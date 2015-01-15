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
    ledger.app.wallet.getBitIdAddress (bitidAddress) =>
      @_httpDo
        method: 'GET'
        url: "bitid/authenticate?address=#{bitidAddress}"
        onSuccess: (authentication) =>
          ledger.app.wallet.signMessageWithBitId authentication, (signature, error) =>
            l signature
            @_httpDo
              method: 'POST'
              url: 'bitid/authenticate'
              parameters: {address: bitidAddress, signature: signature}
              onSuccess: (AuthToken) =>
                ledger.api.RestClient.AuthToken = AuthToken
                l AuthToken
                @_http.setHttpHeader 'X-LedgerWallet-AuthToken', ledger.api.RestClient.AuthToken
                @_httpDo request
              onError: () =>
                postAuthenticationError(ledger.errors.create(ledger.errors.AuthenticationFailed, 'Second step error', error))
        onError: (error) =>
          postAuthenticationError(ledger.errors.create(ledger.errors.AuthenticationFailed, 'First step error', error))

class ledger.api.RestClient

  @singleton: () -> @instance = new @()

  http: () ->
    client = new HttpClient('https://api.ledgerwallet.com/')
    client.authenticated = -> new AuthenticatedClient(client)
    client.setHttpHeader 'X-Ledger-Locale', chrome.i18n.getUILanguage()
    client.setHttpHeader 'X-LedgerWallet-AuthToken', ledger.api.RestClient.AuthToken if ledger.api.RestClient.AuthToken?
    client.setHttpHeader 'X-Ledger-Platform', 'chrome'
    client

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
