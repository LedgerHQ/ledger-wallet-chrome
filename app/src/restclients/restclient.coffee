ledger.api ?= {}

class ledger.api.RestClient

  @singleton: () -> @instance = new @()

  http: () ->
    new HttpClient('https://api.ledgerwallet.com/')

  networkErrorCallback: (callback) ->
    errorCallback = (xhr, status, message) ->
        callback(null, {xhr, status, message, code: ledger.errors.NetworkError})
    errorCallback

  authenticate: (callback) ->
    @http().setHttpHeader 'X-LedgerWallet-AuthToken', ledger.api.RestClient.AuthToken
    if ledger.api.RestClient.AuthToken?
      do callback
    else
      @_performAuthenticationFirstStep () =>


  _performAuthenticationFirstStep: (callback) ->
    ledger.app.wallet.getBitIdAddress (bitidAddress) =>
      @http().get
        url: "bitid/authenticate?address=#{bitidAddress}"
        onSuccess: (authentication) ->
          l authentication
        onError: () ->
          l arguments