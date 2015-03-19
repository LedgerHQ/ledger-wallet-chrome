ledger.api ?= {}

class ledger.api.HttpClient extends @HttpClient
  constructor: () -> super

  authenticated: ->
    authenticatedHttpClient = ledger.api.authenticated(@_baseUrl)
    for key, value of @headers
      authenticatedHttpClient.setHttpHeader key, value
    authenticatedHttpClient

class ledger.api.RestClient
  @API_BASE_URL: ledger.config.restClient.baseUrl

  @singleton: () -> @instance ||= new @()

  http: () ->
    @_client ||= @_httpClientFactory()
    @_client.setHttpHeader 'X-Ledger-Locale', chrome.i18n.getUILanguage()
    @_client.setHttpHeader 'X-Ledger-Platform', 'chrome'
    @_client.setHttpHeader 'X-Ledger-Environment', ledger.env
    @_client

  networkErrorCallback: (callback) ->
    errorCallback = (xhr, status, message) ->
        callback(null, {xhr, status, message, code: ledger.errors.NetworkError})
    errorCallback

  _httpClientFactory: -> new ledger.api.HttpClient(ledger.config.restClient.baseUrl)

class ledger.api.AuthRestClient extends ledger.api.RestClient
  _httpClientFactory: -> super().authenticated(@baseUrl)

@testRestClientAuthenticate = ->
  f = ->
    ledger.app.wallet.getBitIdAddress (address) ->
      r = new ledger.api.AuthRestClient()
      r.http().get
        url: "accountsettings/#{address}"
        onSuccess: () -> l arguments
        onError: () ->
          e arguments
  ledger.app.wallet.getState (state) ->
    if state is ledger.wallet.States.LOCKED
      ledger.app.wallet.unlockWithPinCode '0000', f
    else
      do f
