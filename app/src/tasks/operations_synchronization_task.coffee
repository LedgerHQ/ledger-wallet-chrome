class ledger.tasks.OperationsSynchronizationTask extends ledger.tasks.Task

  constructor: () -> super 'global_operations_synchronizer'
  @instance: new @()

  onStart: () ->
    accountIndex = 0
    ledger.db.contexts.main.on 'update:operation insert:operation', (ev, operations) =>
      @synchronizeConfirmationNumbers(operations)
    iterate = () =>
      if accountIndex >= ledger.wallet.HDWallet.instance.getAccountsCount()
        ledger.app.emit 'wallet:operations:sync:done'
        @stopIfNeccessary()
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
          @retrieveAccountOperations(hdaccount, callback)
        else
          callback?()

      stream.open()

  synchronizeConfirmationNumbers: (operations = null, callback = _.noop) ->
    return
    operations = Operation.find(confirmations: $lt: 2).data() unless operations?
    return if operations.length is 0
    l operations
    ledger.api.TransactionsRestClient.instance.refreshTransaction operations, (refreshedOperations, error) =>
      return @synchronizeConfirmationNumbers(operations, callback) if error?
      l refreshedOperations
      # TODO continue

  flushPendingOperationsStream: () ->
    for transaction in Operation.pendingRawTransactionStream().read()
      for account in Account.all()
        do (transaction, account) ->
          account.addRawTransactionAndSave(transaction)
    ledger.app.emit 'wallet:transactions:new'

  onStop: () ->
    Operation.pendingRawTransactionStream().read()
    Operation.pendingRawTransactionStream().off 'data'