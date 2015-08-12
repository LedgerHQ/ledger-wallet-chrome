
class ledger.api.FeesRestClient extends ledger.api.RestClient

  getEstimatedFees: (callback) ->
    ledger.defer(callback).resolve(
      @http().get(url: 'ledger/estimateFees')
    )