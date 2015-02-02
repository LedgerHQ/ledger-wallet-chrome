class @HttpClient

  constructor: (baseUrl = '') ->
    @baseUrl = baseUrl
    @headers = {}

  # @params {Object} See jQuery.ajax() params.
  # @return A jQuery.jqXHR
  jqAjax: (r) ->
    r.headers = _.extend({}, @headers, r.headers)
    r.data = JSON.stringify(r.data) if r.contentType == 'application/json'
    r.url = @baseUrl + r.url
    r.crossDomain = true
    $.ajax(r)

  # Alias for jqAjax
  do: (r) -> @jqAjax(r)

  # @params {Object} See jQuery.ajax() params.
  # @return A jQuery.jqXHR
  get: (r) ->
    @jqAjax _.extend(r, {type: 'GET', dataType: 'json'})

  # @params {Object} See jQuery.ajax() params.
  # @return A jQuery.jqXHR
  post: (r) ->
    @jqAjax _.extend(r, {type: 'POST', dataType: 'json', contentType: 'application/json'})

  # @params {Object} See jQuery.ajax() params.
  # @return A jQuery.jqXHR
  postForm: (r) ->
    @jqAjax _.extend(r, {type: 'POST', dataType: 'text', contentType: 'application/x-www-form-urlencoded'})

  # @params {Object} See jQuery.ajax() params.
  # @return A jQuery.jqXHR
  put: (r) ->
    @jqAjax _.extend(r, {type: 'PUT', dataType: 'json', contentType: 'application/json'})

  # @params {Object} See jQuery.ajax() params.
  # @return A jQuery.jqXHR
  delete: (r) ->
    @jqAjax _.extend(r, {type: 'DELETE', dataType: 'json'})

  setHttpHeader: (key, value) ->
    @headers[key] = value
    @
