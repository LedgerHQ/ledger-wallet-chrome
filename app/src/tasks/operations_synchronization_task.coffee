class ledger.tasks.OperationsSynchronizationTask extends ledger.tasks.Task

  constructor: () -> super 'global_operations_synchronizer'
  @instance: new @()

  onStart: () ->
    accountIndex = 0
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
    l 'operations'
    ledger.wallet.pathsToAddresses hdaccount.getAllAddressesPaths(), (addresses) =>
      addresses = _.values addresses
      ledger.api.TransactionsRestClient.instance.getTransactions addresses, (transactions, error) =>
        return unless @isRunning()
        return ledger.app.emit 'wallet:operations:sync:failed' if error?
        l transactions
        account = Account.fromHDWalletAccount hdaccount
        for transaction in transactions
          account.addRawTransactionAndSave transaction
        callback?()

  onStop: () ->
