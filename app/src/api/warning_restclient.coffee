
class ledger.api.WarningRestClient extends ledger.api.RestClient

  getWarning: (callback) ->
    ledger.defer(callback).resolve(
      @http().get(url: "http://api.ledgerwallet.com/bitcoin/fork/warning")
    ).promise

ledger.api.WarningRestClient.instance = new ledger.api.WarningRestClient()
