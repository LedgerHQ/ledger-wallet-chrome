class ledger.tasks.OperationsSynchronizationTask extends ledger.tasks.Task

  constructor: () -> super 'global_operations_synchronizer'
  @instance: new @()

  onStart: () ->
    Operation.pendingRawTransactionStream().on 'data', => @flushPendingOperationsStream()
    @flushPendingOperationsStream()
    @synchronizeConfirmationNumbers()

  synchronizeConfirmationNumbers: (operations = null, callback = _.noop) ->
    ops = operations
    operations = Operation.find(confirmations: $lt: 1).data() unless operations?
    return @stopIfNeccessary() if operations.length is 0

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
        @stopIfNeccessary()
        do callback
      else
        _.delay (=> @synchronizeConfirmationNumbers ops, callback), 1000
      return if error?

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