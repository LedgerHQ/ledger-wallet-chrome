class @Account extends Model
  do @init
  @has many: 'operations', sortBy: ['time', 'desc'], onDelete: 'destroy'
  @index 'index'

  @fromHDWalletAccount: (hdAccount) ->
    return null unless hdAccount?
    @find(index: hdAccount.index).first()

  createTransaction: (amount, fees, recipientAddress, callback) ->
    transaction = new ledger.wallet.Transaction()
    transaction.init amount, fees, recipientAddress

  ## Balance management

  retrieveBalance: () ->
    ledger.tasks.BalanceTask.get(@get('index')).startIfNeccessary()

  ## Operations

  addRawTransactionAndSave: (rawTransaction, callback = _.noop) ->
    hdAccount = ledger.wallet.HDWallet.instance?.getAccount(@get('index'))
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
      [insert, update] = @_addRawReceptionTransaction rawTransaction, publicAddresses.concat(changeAddresses)
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
