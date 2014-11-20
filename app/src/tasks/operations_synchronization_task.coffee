class ledger.tasks.OperationsSynchronizationTask extends ledger.tasks.Task

  constructor: () -> super 'global_operations_synchronizer'
  @instance: new @()

  onStart: () ->
    account = ledger.wallet.HDWallet.instance?.getAccount(0)
    ledger.wallet.pathsToAddresses account.getAllChangeAddressesPaths(), (changeAddresses) =>
      ledger.wallet.pathsToAddresses account.getAllPublicAddressesPaths(), (publicAddresses) =>
        publicAddresses = _.values(publicAddresses)
        changeAddresses = _.values(changeAddresses)
        ledger.api.TransactionsRestClient.instance.getTransactions changeAddresses.concat(publicAddresses), (transactions, error) =>
          return unless @isRunning()
          return ledger.app.emit 'wallet:operations:sync:failed' if error?
          account = Account.find(0).exists (exists) =>
            return ledger.app.emit 'wallet:operations:sync:failed' unless exists
            _.async.each transactions, (transaction, done, hasNext) =>
              account.addRawTransaction transaction, =>
                unless hasNext
                  ledger.app.emit 'wallet:operations:sync:done'
                  @stopIfNeccessary()
                do done

  onStop: () ->
