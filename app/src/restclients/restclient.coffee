ledger.api ?= {}

class AuthenticatedClient extends HttpClient

  constructor: (http) ->
    @_http = http
    for name, value of http.constructor::
      if name isnt 'do' and _.isFunction(value)
        do (value) =>
          @[name] = () =>
            ret = value.apply(http, arguments)
            if ret = @_http
              @
            else
              ret
    @_httpDo = http.do.bind(@_http)
    http.do = (request) => @do request

  do: (request) ->
    ledger.app.wallet.getState (state) =>
      throw "Unable to authenticate a locked or blank dongle" unless state is ledger.wallet.States.UNLOCKED

      if ledger.api.RestClient.AuthToken?
        @_http.setHttpHeader 'X-LedgerWallet-AuthToken', ledger.api.RestClient.AuthToken

        @_httpDo request
      else
        @_performAuthenticationAndRequest(request)

  _performAuthenticationAndRequest: (request) ->
    postAuthenticationError = (error) ->
      request.onError?(error)
      request.onComplete?(null, 'error')
    headers =  {"Data-Type": 'json', "Content-Type": 'application/json'}
    ledger.app.wallet.getBitIdAddress (bitidAddress) =>
      @_httpDo
        method: 'GET'
        url: "bitid/authenticate/#{bitidAddress}"
        onSuccess: (authentication) =>
          ledger.app.wallet.signMessageWithBitId authentication.message, (signature, error) =>
            @_httpDo
              method: 'POST'
              url: 'bitid/authenticate'
              headers: headers
              params: {address: bitidAddress, signature: signature}
              onSuccess: (AuthToken) =>
                ledger.api.RestClient.AuthToken = AuthToken.token
                @_http.setHttpHeader 'X-LedgerWallet-AuthToken', ledger.api.RestClient.AuthToken
                @_httpDo(request) if request?
              onError: (r, t, error) =>
                postAuthenticationError(ledger.errors.create(ledger.errors.AuthenticationFailed, 'Second step error', error))
        onError: (r, t, error) =>
          postAuthenticationError(ledger.errors.create(ledger.errors.AuthenticationFailed, 'First step error', error))

class ledger.api.RestClient
  API_BASE_URL: ledger.config.restClient.baseUrl

  @singleton: () -> @instance = new @()

  http: () ->
    client = new HttpClient(@API_BASE_URL)
    client.authenticated = -> new AuthenticatedClient(client)
    client.setHttpHeader 'X-Ledger-Locale', chrome.i18n.getUILanguage()
    client.setHttpHeader 'X-LedgerWallet-AuthToken', ledger.api.RestClient.AuthToken if ledger.api.RestClient.AuthToken?
    client.setHttpHeader 'X-Ledger-Platform', 'chrome'
    client

  networkErrorCallback: (callback) ->
    errorCallback = (xhr, status, message) ->
        callback(null, {xhr, status, message, code: ledger.errors.NetworkError})
    errorCallback

@testRestClientAuthenticate = ->
  f = ->
    r = new ledger.api.RestClient()
    r.http().authenticated().get
      url: 'blockchain'
      onSuccess: -> console.log(arguments)
      onError: -> console.log(arguments)
  ledger.app.wallet.getState (state) ->
    if state is ledger.wallet.States.LOCKED
      ledger.app.wallet.unlockWithPinCode '0000', f
    else
      do f
