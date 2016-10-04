class @Account extends ledger.database.Model
  do @init
  @has
    many: 'operations', onDelete: 'destroy'
    sortBy: Operation.defaultSort
  @has one: 'wallet', forMany: 'accounts', onDelete: 'nullify', sync: yes

  @index 'index', sync: yes
  @sync 'name'
  @sync 'color'
  @sync 'hidden'

  constructor: ->
    super
    @retrieveBalance = _.debounce(@retrieveBalance.bind(@), 200)

  @fromWalletAccount: (hdAccount) ->
    return null unless hdAccount?
    @find(index: hdAccount.index).first()

  @getRemainingAccountCreation: (context = ledger.database.contexts.main) -> ledger.wallet.Wallet.instance.getAccountsCount() - Account.all(context).length

  @displayableAccounts: (context = ledger.database.contexts.main) ->
    accounts =
      for account in Account.find(hidden: {$ne: yes}, context).simpleSort('index').data()
        index: account.get('index'), name: account.get('name'), balance: account.get('total_balance'), color: account.get('color')
    _.sortBy accounts, (account) => account.index

  @hiddenAccounts: (context = ledger.database.contexts.main) ->
    accounts =
      for account in Account.find(hidden: yes, context).simpleSort('index').data()
        index: account.get('index'), name: account.get('name'), balance: account.get('total_balance'), color: account.get('color')
    _.sortBy accounts, (account) => account.index

  @recoverAccount: (index, wallet) ->
    if index is 0
      account = Account.create({index: 0, name: t('common.default_account_name'), hidden: false, color: ledger.preferences.defaults.Accounts.firstAccountColor}).save()
    else
      account = Account.create({index: index, name: _.str.sprintf(t("common.default_recovered_account_name"), index), hidden: false, color: ledger.preferences.defaults.Accounts.recoveredAccountColor}).save()
    account.set('wallet', wallet).save()

  getWalletAccount: -> ledger.wallet.Wallet.instance.getAccount(@get('index'))

  get: (key) ->
    val = super(key)
    if key is 'total_balance' or key is 'unconfirmed_balance'
      return if val? then ledger.Amount.fromSatoshi(val) else ledger.Amount.fromSatoshi(0)
    return val

  set: (key, value) ->
    if key is 'hidden'
      _.defer -> ledger.app.emit 'wallet:balance:changed', Wallet.instance.getBalance()
    super(key, value)

  getExtendedPublicKey: (callback) ->
    d = ledger.defer(callback)
    hdAccount = @getWalletAccount()
    if (xpub = ledger.wallet.Wallet.instance?.xpubCache.get(hdAccount.getRootDerivationPath()))?
      d.resolve(xpub)
    else
      new ledger.wallet.ExtendedPublicKey(ledger.app.dongle, hdAccount.getRootDerivationPath()).initialize (xpub, error) =>
        unless error then d.resolve(xpub.toString()) else d.reject(error)
    d.promise

  serialize: () ->
    $.extend super, { root_path: @getWalletAccount().getRootDerivationPath() }

  # Fast getters

  isHidden: -> @get 'hidden' or no

  isDeletable: -> @get('operations').length is 0

  ## Utxo

  getUtxo: ->
    hdaccount = @getWalletAccount()
    _(Output.utxo()).filter (utxo) -> utxo.get('path').match(hdaccount.getRootDerivationPath())

  ## Balance management

  retrieveBalance: () ->
    totalBalance = @get 'total_balance'
    unconfirmedBalance = @get 'unconfirmed_balance'
    @set 'total_balance', @getBalanceFromUtxo(0).toString()
    @set 'unconfirmed_balance', @getBalanceFromUtxo(0).toString()
    @save()
    if ledger.Amount.fromSatoshi(totalBalance or 0).neq(@get('total_balance') or 0) or ledger.Amount.fromSatoshi(unconfirmedBalance or 0).neq(@get('unconfirmed_balance') or 0)
      ledger.app.emit "wallet:balance:changed", Wallet.instance.getBalance()
    else
      ledger.app.emit "wallet:balance:unchanged", Wallet.instance.getBalance()

  getBalanceFromUtxo: (minConfirmation) ->
    total = ledger.Amount.fromSatoshi(0)
    return total unless @getWalletAccount()?
    utxo = @getUtxo()
    for output in utxo when !output.get('double_spent_priority')? or output.get('double_spent_priority') == 0
      if (output.get('path').match(@getWalletAccount().getRootDerivationPath()) and output.get('transaction').get('confirmations')) >= minConfirmation
        total = total.add(output.get('value'))
    total

  ## Add/Remove/Hidden

  isDeletable: -> @getWalletAccount().isEmpty()

  @isAbleToCreateAccount: -> @chain().count() < ledger.wallet.Wallet.instance.getAccountsCount()

  ## Operations

  ###
    Creates a new transaction asynchronously. The created transaction will only be initialized (i.e. it will only retrieve
    a sufficient number of input to perform the transaction)

    @param {ledger.Amount} amount The amount to send (expressed in satoshi)
    @param {ledger.Amount} fees The miner fees (expressed in satoshi)
    @param {String} address The recipient address
    @option [Function] callback The callback called once the transaction is created
    @return [Q.Promise] A closure
  ###
#  createTransaction: ({amount, fees, address}, callback) ->
#    amount = ledger.Amount.fromSatoshi(amount)
#    fees = ledger.Amount.fromSatoshi(fees)
#    inputsPath = @getWalletAccount().getAllAddressesPaths()
#    ledger.api.TransactionsRestClient.instance.getTransactionsFromPaths inputsPath, (transactions) =>
#      Q.fcall ->
#        if transactions.length > 0
#          ledger.tasks.TransactionConsumerTask.instance.waitForTransactionToBeInserted(_.last(transactions).hash)
#      .then =>
#        unconfirmedOperations = Operation.find($and: [{confirmations: 0}, {type: 'sending'}]).data()
#        excludedInputs = []
#        for op in unconfirmedOperations
#          inputIndexes = op.get 'inputs_index'
#          inputHashes = op.get 'inputs_hash'
#          for __, index in inputIndexes
#            excludedInputs.push([inputIndexes[index], inputHashes[index]])
#        @_createTransactionGetChangeAddressPath @getWalletAccount().getCurrentChangeAddressIndex(), (changePath) =>
#          ledger.wallet.Transaction.create(amount: amount, fees: fees, address: address, inputsPath: inputsPath, changePath: changePath, excludedInputs: excludedInputs, callback)
#      ledger.tasks.TransactionConsumerTask.instance.pushTransactions(transactions)

  createTransaction: ({amount, fees, address, utxo, data}, callback) ->
    amount = ledger.Amount.fromSatoshi(amount)
    fees = ledger.Amount.fromSatoshi(fees)
    changeIndex = @getWalletAccount().getCurrentChangeAddressIndex()
    changePath =  @getWalletAccount().getChangeAddressPath(changeIndex)
    ledger.wallet.Transaction.create(amount: amount, fees: fees, address: address, utxo: utxo, changePath: changePath, data:data, callback)


  ###
    Special get change address path to 'avoid' LW 1.0.0 derivation failure.
  ###
  _createTransactionGetChangeAddressPath: (changeIndex, callback) ->
    changePath =  @getWalletAccount().getChangeAddressPath(changeIndex)
    if ledger.app.dongle.getIntFirmwareVersion() isnt ledger.dongle.Firmwares.V_L_1_0_0
      callback changePath
    else
      ledger.tasks.AddressDerivationTask.instance.getPublicAddress changePath, (xpubAddress) =>
        ledger.app.dongle.getPublicAddress changePath, (address) =>
          address = address.bitcoinAddress.toString(ASCII)
          if xpubAddress is address
            callback?(changePath)
          else
            @_createTransactionGetChangeAddressPath(changeIndex + 1, callback)

  addRawTransactionAndSave: (rawTransaction, callback = _.noop) ->
    hdAccount = ledger.wallet.Wallet.instance?.getAccount(@get('index'))
    ledger.wallet.pathsToAddresses hdAccount.getAllPublicAddressesPaths(), (publicAddresses) =>
      ledger.wallet.pathsToAddresses hdAccount.getAllChangeAddressesPaths(), (changeAddresses) =>
        {inserts, updates} = @_addRawTransaction rawTransaction, _.values(publicAddresses), _.values(changeAddresses)
        @save()
        ledger.app.emit 'wallet:operations:new', inserts if inserts.length > 0
        ledger.app.emit 'wallet:operations:update', updates if updates.length > 0
        callback()

  _addRawTransaction: (rawTransaction, publicAddresses, changeAddresses) ->
    rawTransaction.outputAddresses = []
    rawTransaction.inputAddresses = []
    rawTransaction.outputAddresses = rawTransaction.outputAddresses.concat(output.addresses) for output in rawTransaction.outputs
    rawTransaction.inputAddresses = rawTransaction.inputAddresses.concat(input.addresses) for input in rawTransaction.inputs

    hasAddressesInInput = _.some(rawTransaction.inputAddresses, ((address) -> _.contains(publicAddresses, address) or _.contains(changeAddresses, address)))
    hasAddressesInOutput = _.some(rawTransaction.outputAddresses, ((address) -> _.contains(publicAddresses, address)))

    result = inserts: [], updates: []

    if hasAddressesInInput
      [insert, update] = @_addRawSendTransaction rawTransaction, changeAddresses
      result.inserts.push insert if insert?
      result.updates.push update if update?

    if hasAddressesInOutput
      [insert, update] = @_addRawReceptionTransaction rawTransaction, publicAddresses
      result.inserts.push insert if insert?
      result.updates.push update if update?
    result

  _addRawReceptionTransaction: (rawTransaction, ownAddresses) ->
    value = 0
    for output in rawTransaction.outputs
      if _.select(output.addresses, ((address) -> _.contains(ownAddresses, address))).length > 0
        value += parseInt(output.value) if output.value?

    recipients = (address for address in rawTransaction.outputAddresses when _.contains(ownAddresses, address))
    senders = (address for address in rawTransaction.inputAddresses)
    senders = _.unique(senders)
    recipients = _.unique(recipients)

    uid = "reception_#{rawTransaction.hash}_#{@get('index')}"

    operation = Operation.findOrCreate uid: uid

    operation.set 'hash', rawTransaction['hash']
    operation.set 'fees', rawTransaction['fees']
    operation.set 'time', (new Date(rawTransaction['chain_received_at'])).getTime()
    operation.set 'type', 'reception'
    operation.set 'value', value
    operation.set 'confirmations', rawTransaction['confirmations']
    operation.set 'senders', senders
    operation.set 'recipients', recipients

    isInserted = not operation.isInserted()

    operation.save()
    @add('operations', operation)
    if isInserted
      [operation, null]
    else
      [null, operation]

  _addRawSendTransaction: (rawTransaction, changeAddresses) ->
    value = 0
    for output in rawTransaction.outputs
      if _.select(output.addresses, ((address) -> _.contains(changeAddresses, address) is false)).length > 0
        value += parseInt(output.value) if output.value?

    recipients = (address for address in rawTransaction.outputAddresses when _.contains(changeAddresses, address) is false)
    senders = (address for address in rawTransaction.inputAddresses)
    senders = _.unique(senders)
    recipients = _.unique(recipients)

    uid = "sending#{rawTransaction.hash}_#{@get('index')}"

    operation = Operation.findOrCreate uid: uid

    operation.set 'hash', rawTransaction['hash']
    operation.set 'fees', rawTransaction['fees']
    operation.set 'time', (new Date(rawTransaction['chain_received_at'])).getTime()
    operation.set 'type', 'sending'
    operation.set 'value', value
    operation.set 'confirmations', rawTransaction['confirmations']
    operation.set 'senders', senders
    operation.set 'recipients', recipients

    isInserted = not operation.isInserted()

    operation.save()
    @add('operations', operation)

    if isInserted
      [operation, null]
    else
      [null, operation]

