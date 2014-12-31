ledger.api ?= {}

class AuthenticatedClient

  constructor: (http) ->
    @_http = http
    for name, value of http.constructor::
      l name, value
      if name isnt 'do' and _.isFunction(value)
        @[name] = () -> value.apply(http, arguments)

  do: (request) ->
    attemptNumber = 0

    onFailure = request.onFailure
    onComplete = request.onComplete

    request.onFailure = () ->

    request.onComplete = () ->

    if ledger.api.RestClient.AuthToken?
      @_http.do(request)
    else
      @_performAuthentication()

  _performAuthentication: () ->


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

  authenticated: () -> new AuthenticatedClient(@http())

  _performAuthenticationFirstStep: (callback) ->
    ledger.app.wallet.getBitIdAddress (bitidAddress) =>
      @http().get
        url: "bitid/authenticate?address=#{bitidAddress}"
        onSuccess: (authentication) ->
          l authentication
        onError: () ->
          l arguments