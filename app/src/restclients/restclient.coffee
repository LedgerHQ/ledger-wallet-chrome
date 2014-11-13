ledger.api ?= {}

class ledger.api.RestClient

  http: () ->
    new HttpClient('http://62.210.146.89:9000/')