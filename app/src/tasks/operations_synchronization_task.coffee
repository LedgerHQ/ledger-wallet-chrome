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
        ops = (op for op in (ops or operations) when @checkForDoubleSpent(op) is false)
        @_retryNumber = Math.min(@_retryNumber + 1, 12)
        _.delay (=> @synchronizeConfirmationNumbers ops, callback), ledger.math.fibonacci(@_retryNumber) * 500
      return

  @reset: () ->
    @instance = new @

  checkForDoubleSpent: (operation) ->
    return false if operation.get('confirmations') > 0
    try
      for input_hash, index in operation.get('inputs_hash')
        l "Check for double spent on #{input_hash}"
        input_index = operation.get('inputs_index')[index]
        query = {
          $and: [
            {
              inputs_hash: {$contains: input_hash}
            },
            {
              $and: [
                {inputs_index: {$contains: input_index}},
                {type: operation.get('type')}
              ]
            }
          ]
        }
        suspiciousOperations = Operation.find(query).data()
        suspiciousOperations = (op for op in suspiciousOperations when op.get('inputs_index')[_(op.get('inputs_hash').indexOf(input_hash))] is input_index)
        return if suspiciousOperations.length is 1
        # If one of these is confirmed, invalidate the others
        confirmedIndex =  _(suspiciousOperations).findIndex (i) -> i.get('confirmations') > 0
        if confirmedIndex isnt -1
          for op, index in suspiciousOperations
            l "Deleting ", (index is confirmedIndex), suspiciousOperations[index], suspiciousOperations[confirmedIndex], suspiciousOperations, index, confirmedIndex, input_hash, input_index
            op.delete() unless index is confirmedIndex
          return true

        suspiciousOperations.sort (a, b) ->
          if a.get('fees') > b.get('fees')
            return -1
          else if a.get('fees') < b.get('fees')
            return 1
          else if a.get('time') < b.get('time')
            return -1
          else if a.get('time') < b.get('time')
            return 1
          else
            return 0

        for op, index in suspiciousOperations
          op.set('double_spent_priority', index).save()

        return false
    catch er
      e er