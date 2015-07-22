class ledger.tasks.OperationsSynchronizationTask extends ledger.tasks.Task

  constructor: () -> super 'global_operations_synchronizer'
  @instance: new @()

  onStart: () ->
    @_retryNumber = 0
    @synchronizeConfirmationNumbers()

  synchronizeConfirmationNumbers: (operations = null, callback = _.noop) ->
    ops = operations
    operations = Operation.find(confirmations: $lt: 1).data() unless operations?
    return @stopIfNeccessary() if operations.length is 0

    ledger.api.TransactionsRestClient.instance.refreshTransaction operations, (refreshedOperations, error) =>
      return unless @isRunning()
      unless error?
        ledger.tasks.TransactionConsumerTask.instance.pushTransaction(refreshedOperations)
        @_retryNumber = 0
        @stopIfNeccessary()
        do callback
      else
        @_retryNumber = Math.min(@_retryNumber + 1, 12)
        _.delay (=> @synchronizeConfirmationNumbers ops, callback), ledger.math.fibonacci(@_retryNumber) * 500
      return

  @reset: () ->
    @instance = new @