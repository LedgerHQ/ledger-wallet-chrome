
class ledger.api.BalanceRestClient extends ledger.api.RestClient

  @instance: new @

  getAccountBalance: (account, callback) ->
    account = ledger.wallet.HDWallet.instance.getAccount(account) unless _.isKindOf(account, ledger.wallet.HDWallet.Account)
    addressesPaths = account.getAllAddressesPaths()
    accountBalance = {total: 0, confirmed: 0, unconfirmed: 0}
    ledger.wallet.pathsToAddresses addressesPaths, (addresses) =>
      _.async.eachBatch _.values(addresses), 20, (addresses, done, hasNext) =>
        @http().get
          url: "blockchain/addresses/#{addresses.join(',')}"
          onSuccess: (addressesBalances) ->
            for addressBalance in addressesBalances
              accountBalance.total += parseInt(addressBalance.total.balance)
              accountBalance.confirmed += parseInt(addressBalance.confirmed.balance) if parseInt(addressBalance.confirmed.balance) <= parseInt(addressBalance.total.balance)
            unless hasNext
              accountBalance.unconfirmed = accountBalance.total - accountBalance.confirmed
              callback?(accountBalance)
            do done
          onFailure: @networkErrorCallback(callback)