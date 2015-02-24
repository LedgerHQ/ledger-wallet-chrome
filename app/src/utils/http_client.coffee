class @HttpClient

  constructor: (baseUrl = '') ->
    @baseUrl = baseUrl
    @headers = {}

  # @params {Object} See jQuery.ajax() params.
  # @return A jQuery.jqXHR
  jqAjax: (r) ->
    r.headers = _.extend({}, @headers, r.headers)
    r.success ?= r.onSuccess
    r.error ?= r.onError
    r.data ?= r.body
    r.complete ?= r.onComplete
    r.data = JSON.stringify(r.data) if r.contentType == 'application/json'
    r.url = @baseUrl + r.url
    r.crossDomain = true
    $.ajax(r)

  # Alias for jqAjax. May be redefine.
  do: (r) -> @jqAjax(r)

  # @params {Object} See jQuery.ajax() params.
  # @return A jQuery.jqXHR
  get: (r) ->
    @do _.extend(r, {type: 'GET', dataType: 'json'})

  # @params {Object} See jQuery.ajax() params.
  # @return A jQuery.jqXHR
  post: (r) ->
    @do _.extend(r, {type: 'POST', dataType: 'json', contentType: 'application/json'})

  # @params {Object} See jQuery.ajax() params.
  # @return A jQuery.jqXHR
  postForm: (r) ->
    @do _.extend(r, {type: 'POST', dataType: 'text', contentType: 'application/x-www-form-urlencoded'})

  # @params {Object} See jQuery.ajax() params.
  # @return A jQuery.jqXHR
  put: (r) ->
    @do _.extend(r, {type: 'PUT', dataType: 'json', contentType: 'application/json'})

  # @params {Object} See jQuery.ajax() params.
  # @return A jQuery.jqXHR
  delete: (r) ->
    @do _.extend(r, {type: 'DELETE', dataType: 'json'})

  setHttpHeader: (key, value) ->
    @headers[key] = value
    @
