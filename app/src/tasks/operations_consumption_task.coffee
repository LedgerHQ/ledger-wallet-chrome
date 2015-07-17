class ledger.tasks.OperationsConsumptionTask extends ledger.tasks.Task

  constructor: () -> super 'global_operations_consumer'
  @instance: new @()

  onStart: () ->
    clearTimeout(@_scheduledStart)
    @_retryNumber ||= 0
    stream = ledger.api.TransactionsRestClient.instance.createTransactionStreamForAllObservedPaths()
      .stopOnError (err) ->
        @stopIfNeccessary()
        ledger.app.emit 'wallet:operations:sync:failed', err
        @_retryNumber = Math.min(@_retryNumber + 1, 12)
        @_scheduledStart = _.delay (=> @startIfNeccessary()), ledger.math.fibonacci(@_retryNumber) * 500

    ledger.tasks.TransactionConsumerTask.instance.pushTransactionsFromStream(stream)
    stream.observe().done =>
      @stopIfNeccessary()
      _.defer -> ledger.app.emit 'wallet:operations:sync:done'

  onStop: ->
    super

  @reset: () ->
    clearTimeout(@instance._scheduledStart)
    @instance = new @