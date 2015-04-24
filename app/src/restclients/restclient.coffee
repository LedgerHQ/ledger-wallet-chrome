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
    @_client.setHttpHeader 'X-Ledger-AppVersion', ledger.managers.application.stringVersion()
    @_client.setHttpHeader 'X-Ledger-Environment', ledger.env
    @_client

  networkErrorCallback: (callback) -> (xhr, status, message) -> callback?(null, new ledger.HttpError(xhr))

  _httpClientFactory: -> new ledger.api.HttpClient(ledger.config.restClient.baseUrl)

class ledger.api.AuthRestClient extends ledger.api.RestClient
  _httpClientFactory: -> super().authenticated(@baseUrl)
