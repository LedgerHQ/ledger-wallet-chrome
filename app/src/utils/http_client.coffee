class @HttpClient

  constructor: (baseUrl = '') ->
    @baseUrl = baseUrl
    @headers = {}

  ###
   @private This method should not be used outside this class and its descendants.
   @param [Object] See jQuery.ajax() params.
   @return [jqXHR] A jQuery.jqXHR
  ###
  jqAjax: (r) ->
    @setHttpHeader('X-LedgerWallet-AuthToken', ledger.api.authenticated().getAuthTokenSync()) if ledger.api.authenticated()?.getAuthTokenSync()?
    r.headers = _.extend({}, @headers, r.headers)
    r.success ?= r.onSuccess
    r.error ?= r.onError
    r.data ?= r.body
    r.complete ?= r.onComplete
    r.data = JSON.stringify(r.data) if r.contentType == 'application/json'
    r.url = @baseUrl + r.url
    r.crossDomain = true
    $.ajax(r)

  ###
    Performs a HTTP request. Please prefer shorthand methods as {HttpClient#get} or {HttpClient#post}.

    @example Simple Usage with callbacks
      http = new HttpClient("http://paristocrats.com")
      http.do
        type: 'GET'
        data: {what: 'score'}
        onSuccess: (data, statusText, jqXHR) ->
          ... Handle success ...
        onError: (jqXHR, status) ->
          ... Handle error ...

    @example Simple Usage with Q.Promise
       http = new HttpClient("http://paristocrats.com")
        http
          .do type: 'GET', data: {what: 'score'}
          .then (data, statusText, jqXHR) ->
            ... Handle success ...
          .fail (jqXHR, statusText) ->
            ... Handle error ...
          .done()

    @param [Object] r A jQuery style request {http://api.jquery.com/jquery.ajax/#jQuery-ajax-settings jQuery Ajax Setting}
    @return [Q.Promise] A Q.Promise
  ###
  do: (r) -> Q(@jqAjax(r))

  ###
    Performs a HTTP GET request.

    @param [Object] r A jQuery style request {http://api.jquery.com/jquery.ajax/#jQuery-ajax-settings jQuery Ajax Setting}
    @return [Q.Promise] A Q.Promise
    @see {HttpClient#do}
  ###
  get: (r) ->
    @do _.extend(r, {type: 'GET', dataType: 'json'})

  ###
    Performs a HTTP POST request.

    @param [Object] r A jQuery style request {http://api.jquery.com/jquery.ajax/#jQuery-ajax-settings jQuery Ajax Setting}
    @return [Q.Promise] A Q.Promise
    @see HttpClient#do
  ###
  post: (r) ->
    @do _.extend(r, {type: 'POST', dataType: 'json', contentType: 'application/json'})

  ###
   Performs a HTTP POST request using a form url encoded body.

   @param [Object] r A jQuery style request {http://api.jquery.com/jquery.ajax/#jQuery-ajax-settings jQuery Ajax Setting}
   @return [Q.Promise] A Q.Promise
   @see HttpClient#do
  ###
  postForm: (r) ->
    @do _.extend(r, {type: 'POST', dataType: 'text', contentType: 'application/x-www-form-urlencoded'})

  ###
   Performs a HTTP PUT request.

   @param [Object] r A jQuery style request {http://api.jquery.com/jquery.ajax/#jQuery-ajax-settings jQuery Ajax Setting}
   @return [Q.Promise] A Q.Promise
   @see HttpClient#do
  ###
  put: (r) ->
    @do _.extend(r, {type: 'PUT', dataType: 'json', contentType: 'application/json'})

  ###
   Performs a HTTP DELETE request.

   @param [Object] r A jQuery style request {http://api.jquery.com/jquery.ajax/#jQuery-ajax-settings jQuery Ajax Setting}
   @return [Q.Promise] A Q.Promise
   @see HttpClient#do
  ###
  delete: (r) ->
    @do _.extend(r, {type: 'DELETE', dataType: 'json'})

  ###
    Sets custom http header to the client. These headers will be automatically included in each HTTP request.

    @param [String] key The name of the HTTP header field
    @param [String] value The value for the HTTP header field
  ###
  setHttpHeader: (key, value) ->
    @headers[key] = value
    @
