class @HttpClient

  _headerJson:
    dataType: 'json'
    contentType: 'application/json'

  _headerUrlEncode:
    dataType: 'text'
    contentType: 'application/x-www-form-urlencoded'

  constructor: (baseUrl = '') ->
    @baseUrl = baseUrl

  do: (r) ->
    request =
      url: @baseUrl + r.url
      type: r.method
      success: r.onSuccess
      error: r.onError
      crossDomain: true
      complete: r.onComplete
      headers: @headers
      data: r.params
    for key, value of r.headers
      request[key] = value
    $.ajax request

  performHttpRequest: (method, url, headers, parameters, success, error, complete) ->
    if _.isObject method
      method.header = headers
      this.do method
    else if _.isObject url
      url.method = method
      url.headers = headers
      this.do url
    else
      this.do
        method: method
        url: url
        headers: headers
        params: parameters
        onSuccess: success
        onError: error
        onComplete: complete



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