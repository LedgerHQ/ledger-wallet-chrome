class @RestClient

  http: ->
    @_httpClient ?= new HttpClient('http://vr.coinhouse.epicdream.fr/')
    @_httpClient
