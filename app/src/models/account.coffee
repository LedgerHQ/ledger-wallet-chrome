class @Account extends ledger.database.Model
  do @init
  @has
    many: 'operations', onDelete: 'destroy'
    sortBy: (a, b) ->
      d = b.time - a.time
      if d is 0
        if a.type > b.type then 1 else -1
      else if d > 0
        1
      else
        -1

  @index 'index'

  @fromWalletAccount: (hdAccount) ->
    return null unless hdAccount?
    @find(index: hdAccount.index).first()

  getWalletAccount: () -> ledger.wallet.Wallet.instance.getAccount(@get('index'))

  serialize: () ->
    $.extend super, { root_path: @getWalletAccount().getRootDerivationPath() }

  ## Balance management

  retrieveBalance: () ->
    ledger.tasks.BalanceTask.get(@get('index')).startIfNeccessary()

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
  createTransaction: ({amount, fees, address}, callback) ->
    amount = ledger.Amount.fromSatoshi(amount)
    fees = ledger.Amount.fromSatoshi(fees)
    inputsPath = @getWalletAccount().getAllAddressesPaths()
    @_createTransactionGetChangeAddressPath @getWalletAccount().getCurrentChangeAddressIndex(), (changePath) =>
      ledger.wallet.Transaction.create(amount: amount, fees: fees, address: address, inputsPath: inputsPath, changePath: changePath, callback)

  ###
    Special get change address path to 'avoid' LW 1.0.0 derivation failure.
  ###
  _createTransactionGetChangeAddressPath: (changeIndex, callback) ->
    changePath =  @getWalletAccount().getChangeAddressPath(changeIndex)
    if ledger.app.dongle.getIntFirmwareVersion() isnt ledger.dongle.Firmware.V_LW_1_0_0
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

