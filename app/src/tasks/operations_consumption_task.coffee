class ledger.tasks.OperationsConsumptionTask extends ledger.tasks.Task

  constructor: () -> super 'global_operations_consumer'
  @instance: new @()

  onStart: () ->
    iterate = (accountIndex) =>
      if accountIndex >= ledger.wallet.HDWallet.instance.getAccountsCount()
        ledger.app.emit 'wallet:operations:sync:done'
        return
      hdaccount = ledger.wallet.HDWallet.instance?.getAccount(accountIndex)
      @retrieveAccountOperations hdaccount, =>
        accountIndex += 1
        if accountIndex < Wallet.instance.get('accounts').length
          iterate()
        else
          @stopIfNeccessary()
    iterate(0)

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

      stream.open()

  onStop: () ->

  @reset: () ->
    @instance = new @