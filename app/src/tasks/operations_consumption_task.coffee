class ledger.tasks.OperationsConsumptionTask extends ledger.tasks.Task

  constructor: () -> super 'global_operations_consumer'
  @instance: new @()

  onStart: () ->
    iterate = (accountIndex) =>
      return @stopIfNeccessary() if accountIndex >= Wallet.instance.get('accounts').length
      if accountIndex >= ledger.wallet.Wallet.instance.getAccountsCount()
        @stopIfNeccessary()
        _.defer -> ledger.app.emit 'wallet:operations:sync:done'
        return
      hdaccount = ledger.wallet.Wallet.instance?.getAccount(accountIndex)
      @retrieveAccountOperations hdaccount, =>
        iterate(accountIndex + 1)
    iterate(0)

  retrieveAccountOperations: (hdaccount, callback) ->
    l "RETRIEVE ALL FOR ", hdaccount.getAllObservedAddressesPaths(), _.clone(hdaccount._account)
    ledger.wallet.pathsToAddresses hdaccount.getAllObservedAddressesPaths(), (addresses) =>
      l "GOT ADDRESSES ", addresses
      addresses = _.values addresses
      stream = ledger.api.TransactionsRestClient.instance.createTransactionStream(addresses)
      stream.on 'data', =>
        return unless @isRunning()
        account = Account.fromWalletAccount hdaccount
        for transaction in stream.read()
          account.addRawTransactionAndSave transaction

      stream.on 'close', =>
        l "Stream at end", _.clone(stream), " [DONE]"
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