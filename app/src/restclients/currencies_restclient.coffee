class ledger.api.CurrenciesRestClient extends ledger.api.RestClient

  getAllCurrencies: (onSuccessCB, error) ->
    r = new ledger.api.RestClient()
    r.http().get
      url: "currencies/all/exchange_rates"
      onSuccess: (data, statusText, jqXHR) ->
        onSuccessCB(data, null)

      onError: @networkErrorCallback(onSuccessCB)


  getCurrency: (onSuccessCB, error) ->
    r = new ledger.api.RestClient()
    r.http().get
      url: "currencies/" + currency + "/exchange_rate"
      onSuccess: (data, statusText, jqXHR) ->
        onSuccessCB(data, null)

      onError: @networkErrorCallback(onSuccessCB)