
class ledger.api.BalanceRestClient extends ledger.api.RestClient

  @instance: new @

  getAccountBalance: (account, callback) ->
    account = ledger.wallet.HDWallet.instance.getAccount(account) unless _.isKindOf(account, ledger.wallet.HDWallet.instance)
    l account
    addressesPaths = [].concat(account.getAllChangeAddressesPaths()).concat(account.getAllPublicAddressesPaths())
    l addressesPaths
    ledger.wallet.pathsToAddresses addressesPaths, (addresses) =>
      l addresses
      _.async.eachBatch _.values(addresses), 20, (addresses, done, hasNext) =>
        @http().get
          url: "blockchain/addresses/#{addresses.join(',')}"
          onSuccess: (response) ->
            l response