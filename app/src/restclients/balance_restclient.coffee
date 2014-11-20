
class ledger.api.BalanceRestClient extends ledger.api.RestClient

  @instance: new @

  getAccountBalance: (account, callback) ->
    account = ledger.wallet.HDWallet.instance.getAccount(account) unless _.isKindOf(account, ledger.wallet.HDWallet.instance)
    addressesPaths = [].concat(account.getAllChangeAddressesPaths()).concat(account.getAllPublicAddressesPaths())
    accountBalance = {total: 0, confirmed: 0, unconfirmed: 0}
    ledger.wallet.pathsToAddresses addressesPaths, (addresses) =>
      _.async.eachBatch _.values(addresses), 20, (addresses, done, hasNext) =>
        @http().get
          url: "blockchain/addresses/#{addresses.join(',')}"
          onSuccess: (addressesBalances) ->
            for addressBalance in addressesBalances
              accountBalance.total += addressBalance.total.balance
              accountBalance.confirmed += addressBalance.confirmed.balance if addressBalance.confirmed.balance < addressBalance.total.balance
            unless hasNext
              accountBalance.unconfirmed = accountBalance.total - accountBalance.confirmed
              callback?(accountBalance)
            do done
          onError: @networkErrorCallback(callback)