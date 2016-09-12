
class ledger.api.FeesRestClient extends ledger.api.RestClient

  getEstimatedFees: (callback) ->
    ledger.defer(callback).resolve(
      @http().get(url: "blockchain/v2/#{ledger.config.network.ticker}/fees")
    )