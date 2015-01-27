class @HttpClient

  _headerJson:
    "Data-Type": 'json'
    "Content-Type": 'application/json'

  _headerUrlEncode:
    "Data-Type": 'text'
    "Content-Type": 'application/x-www-form-urlencoded'

  constructor: (baseUrl = '') ->
    @baseUrl = baseUrl
    @headers = {}

  do: (r) ->
    data = r.params
    headers = _.extend({}, @headers, r.headers || {})
    if headers["Content-Type"] == 'application/json' && _.contains(['POST', 'PUT'], r.method)
      data = JSON.stringify data
    request =
      url: @baseUrl + r.url
      type: r.method
      success: r.onSuccess
      error: r.onError
      crossDomain: true
      complete: r.onComplete
      headers: headers
      data: data
    console.log(request)
    $.ajax request

  performHttpRequest: (method, url, headers, parameters, success, error, complete) ->
    if _.isObject method
      method.header = _.extend(method.header || {}, headers)
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
    @performHttpRequest 'GET', url, {"Data-Type": 'json'}, parameters, success, error, complete

  post: (url, parameters, success, error, complete) ->
    @performHttpRequest 'POST', url, {"Data-Type": 'json', "Content-Type": 'application/json'}, parameters, success, error, complete

  postForm: (url, parameters, success, error, complete) ->
    @performHttpRequest 'POST', url, {"Data-Type": 'text', "Content-Type": 'application/x-www-form-urlencoded'}, parameters, success, error, complete

  put: (url, parameters, success, error, complete) ->
    @performHttpRequest 'PUT', url, {"Data-Type": 'json', "Content-Type": 'application/json'}, parameters, success, error, complete

  delete: (url, parameters, success, error, complete) ->
    @performHttpRequest 'DELETE', url, {"Data-Type": 'json'}, parameters, success, error, complete

  setHttpHeader: (key, value) ->
    @headers[key] = value
    @
