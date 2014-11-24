class ledger.tasks.OperationsSynchronizationTask extends ledger.tasks.Task

  constructor: () -> super 'global_operations_synchronizer'
  @instance: new @()

  onStart: () ->
    l 'operations'
    account = ledger.wallet.HDWallet.instance?.getAccount(0)
    l account, account.getAllChangeAddressesPaths()
    ledger.wallet.pathsToAddresses account.getAllChangeAddressesPaths(), (changeAddresses) =>
      l 'CHANGE', changeAddresses
      ledger.wallet.pathsToAddresses account.getAllPublicAddressesPaths(), (publicAddresses) =>
        l 'PUBLIC', publicAddresses
        publicAddresses = _.values(publicAddresses)
        changeAddresses = _.values(changeAddresses)
        addresses = changeAddresses.concat(publicAddresses)
        l addresses
        ledger.api.TransactionsRestClient.instance.getTransactions addresses, (transactions, error) =>
          l transactions
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
