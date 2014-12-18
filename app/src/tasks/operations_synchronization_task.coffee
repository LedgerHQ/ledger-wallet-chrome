class ledger.tasks.OperationsSynchronizationTask extends ledger.tasks.Task

  _retrieveAccountsOperationIsRunning: no
  _synchronizeConfirmationNumbersIsRunning: no

  constructor: () -> super 'global_operations_synchronizer'
  @instance: new @()

  onStart: () ->
    @_retrieveAccountsOperationIsRunning = yes
    @_synchronizeConfirmationNumbersIsRunning = yes
    accountIndex = 0
    ledger.db.contexts.main.on 'insert:operation', () =>
      if @isRunning()
        _.defer => @synchronizeConfirmationNumbers()
      else
        @startIfNeccessary()
    iterate = () =>
      if accountIndex >= ledger.wallet.HDWallet.instance.getAccountsCount()
        ledger.app.emit 'wallet:operations:sync:done'
        return
      hdaccount = ledger.wallet.HDWallet.instance?.getAccount(accountIndex)
      @retrieveAccountOperations(hdaccount, iterate)
      accountIndex += 1
    iterate()

    Operation.pendingRawTransactionStream().on 'data', => @flushPendingOperationsStream()
    @flushPendingOperationsStream()
    @synchronizeConfirmationNumbers()

  retrieveAccountOperations: (hdaccount, callback) ->
    ledger.wallet.pathsToAddresses hdaccount.getAllAddressesPaths(), (addresses) =>
      addresses = _.values addresses
      stream = ledger.api.TransactionsRestClient.instance.createTransactionStream(addresses)
      stream.on 'data', =>
        return unless @isRunning()
        account = Account.fromHDWalletAccount hdaccount
        for transaction in stream.read()
          account.addRawTransactionAndSave transaction

      stream.on 'close', =>
        return unless @isRunning()
        if stream.hasError()
          ledger.app.emit 'wallet:operations:sync:failed'
          _.delay @retrieveAccountOperations(hdaccount, callback), 1000
        else
          callback?()
          @_retrieveAccountsOperationIsRunning = no
          @stopIfPossible()

      stream.open()

  getRetrieveAccountsOperationIsRunning: ->
    @_retrieveAccountsOperationIsRunning

  synchronizeConfirmationNumbers: (operations = null, callback = _.noop) ->
    ops = operations
    operations = Operation.find(confirmations: $lt: 1).data() unless operations?
    if operations.length is 0
      @_synchronizeConfirmationNumbersIsRunning = no
      @stopIfPossible()
      return
    ledger.api.TransactionsRestClient.instance.refreshTransaction operations, (refreshedOperations, error) =>
      return unless @isRunning()
      unless error?
        updatesCount = 0
        for refreshedOperation in refreshedOperations
          operationsToUpdate = _.select(operations, ((op) -> op.get('hash') is refreshedOperation.hash))
          for operationToUpdate in operationsToUpdate
            if operationToUpdate.refresh().get('confirmations') isnt refreshedOperation['confirmations']
              operationToUpdate.set('confirmations', refreshedOperation['confirmations']).save()
              updatesCount += 1
        ledger.app.emit 'wallet:operations:update', operationsToUpdate if updatesCount > 0
      _.delay (=> @synchronizeConfirmationNumbers(ops, callback)), 1000
      return if error?

  stopIfPossible: ->
    if not @_retrieveAccountsOperationIsRunning and not @_synchronizeConfirmationNumbersIsRunning
      @stopIfNeccessary()

  flushPendingOperationsStream: () ->
    for transaction in Operation.pendingRawTransactionStream().read()
      for account in Account.all()
        do (transaction, account) ->
          account.addRawTransactionAndSave(transaction)

  onStop: () ->
    Operation.pendingRawTransactionStream().read()
    Operation.pendingRawTransactionStream().off 'data'

  @reset: () ->
    @instance = new @