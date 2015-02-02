ledger.api ?= {}

class AuthenticatedClient extends HttpClient

  # Redefine do to ensure Connection is Authentified.
  do: (request) ->
    # ledger.app.wallet.getState (state) =>
    #   throw "Unable to authenticate a locked or blank dongle" unless state is ledger.wallet.States.UNLOCKED
    throw "Unable to authenticate a locked or blank dongle" unless ledger.wallet.isPluggedAndUnlocked()
    if @headers['X-LedgerWallet-AuthToken']?
      super(request)
    else
      @_performAuthenticationAndRequest(request)

  _performAuthenticationAndRequest: (request) ->
    postAuthenticationError = (error) -> request.error?(error)
    ledger.app.wallet.getBitIdAddress (bitidAddress) =>
      @get(
        url: "bitid/authenticate/#{bitidAddress}"
      ).done( (authentication) =>
        ledger.app.wallet.signMessageWithBitId authentication.message, (signature, error) =>
          @post(
            url: 'bitid/authenticate'
            data: {address: bitidAddress, signature: signature}
          ).done( (AuthToken) =>
            @headers['X-LedgerWallet-AuthToken'] = ledger.api.RestClient.AuthToken
            @do(request)
          ).fail (r, t, error) =>
            postAuthenticationError(ledger.errors.create(ledger.errors.AuthenticationFailed, 'Second step error', error))
      ).fail (r, t, error) =>
        postAuthenticationError(ledger.errors.create(ledger.errors.AuthenticationFailed, 'First step error', error))

class ledger.api.RestClient
  API_BASE_URL: ledger.config.restClient.baseUrl

  @singleton: () -> @instance = new @()

  constructor: () ->
    @http = new AuthenticatedClient(@API_BASE_URL)
    @http.setHttpHeader 'X-Ledger-Locale', chrome.i18n.getUILanguage()
    @http.setHttpHeader 'X-Ledger-Platform', 'chrome'

  http: () ->
    @http

  networkErrorCallback: (callback) ->
    errorCallback = (xhr, status, message) ->
        callback(null, {xhr, status, message, code: ledger.errors.NetworkError})
    errorCallback

@testRestClientAuthenticate = ->
  f = ->
    r = new ledger.api.RestClient()
    r.http().get(
      url: 'blockchain'
    ).done( -> console.log(arguments)
    ).fail( -> console.log(arguments) )
  ledger.app.wallet.getState (state) ->
    if state is ledger.wallet.States.LOCKED
      ledger.app.wallet.unlockWithPinCode '0000', f
    else
      do f
