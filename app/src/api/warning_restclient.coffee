
class ledger.api.WarningRestClient extends ledger.api.RestClient

  getWarning: (callback) ->
    ledger.defer(callback).resolve(
      @http().get(url: "todo")
    )
