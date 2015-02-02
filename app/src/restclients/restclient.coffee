ledger.api ?= {}

class AuthenticatedClient extends HttpClient

  # Redefine do to ensure Connection is Authentified.
  do: (request) ->
    throw "Unable to authenticate a locked or blank dongle" unless ledger.wallet.isPluggedAndUnlocked()
    if @isAuthenticated()
      super(request)
    else
      @authenticate(request)

  authenticate: (request) ->
    postAuthenticationError = (error) -> request.error?(error)
    ledger.app.wallet.getBitIdAddress (bitidAddress) =>
      @jqAjax(
        type: 'GET'
        url: "bitid/authenticate/#{bitidAddress}"
        dataType: 'json'
      ).done( (authentication) =>
        ledger.app.wallet.signMessageWithBitId authentication.message, (signature, error) =>
          @jqAjax(
            type: 'POST'
            url: 'bitid/authenticate'
            data: {address: bitidAddress, signature: signature}
            contentType: 'application/json'
            dataType: 'json'
          ).done( (authToken) =>
            @headers['X-LedgerWallet-AuthToken'] = authToken.token
            @jqAjax(request) if request?
          ).fail (r, t, error) =>
            postAuthenticationError(ledger.errors.create(ledger.errors.AuthenticationFailed, 'Second step error', error))
      ).fail (r, t, error) =>
        postAuthenticationError(ledger.errors.create(ledger.errors.AuthenticationFailed, 'First step error', error))

  isAuthenticated: ->
    @headers['X-LedgerWallet-AuthToken']?

class ledger.api.RestClient
  API_BASE_URL: ledger.config.restClient.baseUrl

  @singleton: () -> @instance = new @()

  constructor: () ->
    @http = @_httpClientFactory()
    @http.setHttpHeader 'X-Ledger-Locale', chrome.i18n.getUILanguage()
    @http.setHttpHeader 'X-Ledger-Platform', 'chrome'

  networkErrorCallback: (callback) ->
    errorCallback = (xhr, status, message) ->
        callback(null, {xhr, status, message, code: ledger.errors.NetworkError})
    errorCallback

  _httpClientFactory: ->
    new HttpClient(@API_BASE_URL)

class ledger.api.AuthRestClient extends ledger.api.RestClient
  _httpClientFactory: ->
    new AuthenticatedClient(@API_BASE_URL)

@testRestClientAuthenticate = ->
  f = ->
    r = new ledger.api.RestClient()
    r.http.get(
      url: 'blockchain'
    ).done( -> console.log(arguments)
    ).fail( -> console.log(arguments) )
  ledger.app.wallet.getState (state) ->
    if state is ledger.wallet.States.LOCKED
      ledger.app.wallet.unlockWithPinCode '0000', f
    else
      do f
