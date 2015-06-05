class ledger.tasks.OperationsConsumptionTask extends ledger.tasks.Task

  constructor: () -> super 'global_operations_consumer'
  @instance: new @()

  onStart: () ->
    l 'Start consumer'
    iterate = (accountIndex) =>
      l 'Iteration accountIndex', accountIndex
      return @stopIfNeccessary() if accountIndex >= Wallet.instance.get('accounts').length
      l 'Iterating consumer', Wallet.instance, Wallet.instance.get('accounts'), Wallet.instance.get('accounts').length
      if accountIndex >= ledger.wallet.Wallet.instance.getAccountsCount()
        ledger.app.emit 'wallet:operations:sync:done'
        return
      hdaccount = ledger.wallet.Wallet.instance?.getAccount(accountIndex)
      l 'Retrieve account operations'
      @retrieveAccountOperations hdaccount, =>
        l 'Iterating consumer call next'
        iterate(accountIndex + 1)
    iterate(0)

  retrieveAccountOperations: (hdaccount, callback) ->
    l 'Retrieve account', hdaccount, hdaccount.getAllObservedAddressesPaths()
    ledger.wallet.pathsToAddresses hdaccount.getAllObservedAddressesPaths(), (addresses) =>
      l "Retrieved addresses", addresses
      addresses = _.values addresses
      stream = ledger.api.TransactionsRestClient.instance.createTransactionStream(addresses)
      stream.on 'data', =>
        return unless @isRunning()
        account = Account.fromWalletAccount hdaccount
        l 'Add transaction', account
        for transaction in stream.read()
          account.addRawTransactionAndSave transaction

      stream.on 'close', =>
        return unless @isRunning()
        if stream.hasError()
          ledger.app.emit 'wallet:operations:sync:failed'
          _.delay @retrieveAccountOperations(hdaccount, callback), 1000
        else
          callback?()

      stream.open()

  onStop: () ->

  @reset: () ->
    @instance = new @