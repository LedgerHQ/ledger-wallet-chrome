class @HttpClient

  _headerJson:
    dataType: 'json'
    contentType: 'application/json'

  _headerUrlEncode:
    dataType: 'text'
    contentType: 'application/x-www-form-urlencoded'

  constructor: (baseUrl = '') ->
    @baseUrl = baseUrl

  performHttpRequest: (method, url, headers, parameters, success, error, complete) ->
    request =
      url: @baseUrl + url
      type: method
      success: success
      error: error
      crossDomain: true
      complete: complete
      headers: @headers
      data: parameters
    for key, value of headers
      request[key] = value
    $.ajax request

  get: (url, parameters, success, error, complete) ->
    @performHttpRequest 'GET', url, @_headerJson, parameters, success, error, complete

  post: (url, parameters, success, error, complete) ->
    @performHttpRequest 'POST', url, @_headerJson, parameters, success, error, complete

  postForm: (url, parameters, success, error, complete) ->
    @performHttpRequest 'POST', url, @_headerUrlEncode, parameters, success, error, complete

  put: (url, parameters, success, error, complete) ->
    @performHttpRequest 'PUT', url, @_headerJson, parameters, success, error, complete

  delete: (url, parameters, success, error, complete) ->
    @performHttpRequest 'DELETE', url, @_headerJson, parameters, success, error, complete