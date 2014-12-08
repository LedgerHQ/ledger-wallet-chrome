class ledger.tasks.OperationsSynchronizationTask extends ledger.tasks.Task

  constructor: () -> super 'global_operations_synchronizer'
  @instance: new @()

  onStart: () ->
    accountIndex = 0
    ledger.db.contexts.main.on 'update:operation insert:operation', (ev, operations) =>
      @synchronizeConfirmationNumbers(operations)
    @synchronizeConfirmationNumbers()
    iterate = () =>
      if accountIndex >= ledger.wallet.HDWallet.instance.getAccountsCount()
        ledger.app.emit 'wallet:operations:sync:done'
        @stopIfNeccessary()
        return
      hdaccount = ledger.wallet.HDWallet.instance?.getAccount(accountIndex)
      @retrieveAccountOperations(hdaccount, iterate)
      accountIndex += 1
    iterate()

  retrieveAccountOperations: (hdaccount, callback) ->
    ledger.wallet.pathsToAddresses hdaccount.getAllAddressesPaths(), (addresses) =>
      addresses = _.values addresses
      ledger.api.TransactionsRestClient.instance.getTransactions addresses, (transactions, error) =>
        return unless @isRunning()
        return ledger.app.emit 'wallet:operations:sync:failed' if error?
        account = Account.fromHDWalletAccount hdaccount
        for transaction in transactions
          account.addRawTransactionAndSave transaction
        callback?()

  synchronizeConfirmationNumbers: (operations = null, callback = _.noop) ->
    operations = Operation.find(confirmations: $lt: 2).data() unless operations?
    ledger.api.TransactionsRestClient.refreshTransaction operations, (refreshedOperations, error) ->
      return @synchronizeConfirmationNumbers(operations, callback) if error?
      l refreshedOperations
      # TODO continue

  onStop: () ->
