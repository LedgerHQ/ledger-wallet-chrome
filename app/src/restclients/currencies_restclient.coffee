class ledger.api.CurrenciesRestClient extends ledger.api.RestClient

  ###
    Get infos for all currencies

    @param [Function] cb Callback
  ###
  getAllCurrencies: (cb) ->
    r = new ledger.api.RestClient()
    r.http().get
      url: "currencies/all/exchange_rates"
      onSuccess: (data) ->
        cb?(data, null)
      onError: @networkErrorCallback(cb)


  getCurrency: (currency, cb) ->
    r = new ledger.api.RestClient()
    r.http().get
      url: "currencies/" + currency + "/exchange_rate"
      onSuccess: (data) ->
        cb?(data, null)
      onError: @networkErrorCallback(cb)