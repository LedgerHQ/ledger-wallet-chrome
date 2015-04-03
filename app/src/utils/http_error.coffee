
class ledger.HttpError extends ledger.StandardError

  constructor: (xhr) ->
    super ledger.errors.NetworkError, xhr.statusText
    @_xhr = xhr

  getXmlHttpRequest: -> @_xhr

  getStatusCode: -> @getXmlHttpRequest().status
  getStatusText: -> @getXmlHttpRequest().statusText

  isDueToNoInternetConnectivity: -> @getStatusCode() is 0