ledger.api ?= {}

class ledger.api.RestClient

  @singleton: () -> @.instance = new @()

  http: () ->
    new HttpClient('http://62.210.146.89:9000/')

  errorCallback: (callback) ->
    errorCallback = () ->
      (xhr, status, message) =>
        callback(null, {xhr, status, message})
    errorCallback
