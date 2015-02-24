ledger.api ?= {}

class AuthenticatedClient extends HttpClient

  # Redefine do to ensure Connection is Authentified.
  do: (request) ->
    throw "Unable to authenticate a locked or blank dongle" unless ledger.wallet.isPluggedAndUnlocked()
    if @isAuthenticated()
      super(request)
    else if not @isAuthenticated() and AuthenticatedClient.AuthToken?
      @headers['X-LedgerWallet-AuthToken'] = AuthenticatedClient.AuthToken
      super request
    else
      @authenticate()
      .then => Q(@jqAjax(request))
      .catch (error) =>
        request.error?(error)
        return

  authenticate: () ->
    return @_authPromise if @_authPromise?
    d = Q.defer()
    @_authPromise = d.promise
    ledger.app.wallet.getBitIdAddress (bitidAddress) =>
      @jqAjax(
        type: 'GET'
        url: "bitid/authenticate/#{bitidAddress}"
        dataType: 'json'
      ).done( (authentication) =>
        ledger.app.wallet.signMessageWithBitId authentication.message, (signature, error) =>
          d.reject(ledger.errors.create(ledger.errors.AuthenticationFailed, 'Signing challenge step error', error)) if error?
          @jqAjax(
            type: 'POST'
            url: 'bitid/authenticate'
            data: {address: bitidAddress, signature: signature}
            contentType: 'application/json'
            dataType: 'json'
          ).done( (authToken) =>
            AuthenticatedClient.AuthToken = authToken.token
            @headers['X-LedgerWallet-AuthToken'] = authToken.token
            d.resolve()
          ).fail (r, t, error) =>
            d.reject(ledger.errors.create(ledger.errors.AuthenticationFailed, 'Post signed challenge step error', error))
      ).fail (r, t, error) =>
        d.reject(ledger.errors.create(ledger.errors.AuthenticationFailed, 'Getting challenge step error', error))
    @_authPromise

  isAuthenticated: ->
    @headers['X-LedgerWallet-AuthToken']?

  @AuthToken: null

class ledger.api.HttpClient extends @HttpClient
  authenticated: -> ledger.api.authenticated()

class ledger.api.RestClient
  @API_BASE_URL: ledger.config.restClient.baseUrl

  @singleton: () -> @instance ||= new @()

  http: () ->
    @_client ?= @_httpClientFactory()
    @http.setHttpHeader 'X-Ledger-Locale', chrome.i18n.getUILanguage()
    @http.setHttpHeader 'X-Ledger-Platform', 'chrome'
    @_client

  networkErrorCallback: (callback) ->
    errorCallback = (xhr, status, message) ->
        callback(null, {xhr, status, message, code: ledger.errors.NetworkError})
    errorCallback

  _httpClientFactory: -> new ledger.api.HttpClient(@constructor.API_BASE_URL)

class ledger.api.AuthRestClient extends ledger.api.RestClient
  _httpClientFactory: -> super().authenticated()

@testRestClientAuthenticate = ->
  f = ->
    r = new ledger.api.AuthRestClient()
    r.http.get
      url: 'blockchain'
      onSuccess: l
      onError: e
  ledger.app.wallet.getState (state) ->
    if state is ledger.wallet.States.LOCKED
      ledger.app.wallet.unlockWithPinCode '0000', f
    else
      do f
