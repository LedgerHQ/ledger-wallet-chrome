ledger.api ?= {}

class ledger.api.RestClient

  @singleton: () -> @.instance = new @()

  http: () ->
    new HttpClient('https://api.ledgerwallet.com/')

  errorCallback: (callback) ->
    errorCallback = () ->
      (xhr, status, message) =>
        callback(null, {xhr, status, message})
    errorCallback
