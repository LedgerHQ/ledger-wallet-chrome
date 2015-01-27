
class ledger.api.SyncRestClient extends ledger.api.RestClient

  @instance: new @

  constructor: (addr) ->
    @authHttp = @http().authenticated()
    @basePath = "accountsettings/#{addr}"

  # @param [Function] cb A callback function with object.md5 as argument.
  # @return A jQuery promise
  get_settings_md5: ->
    @_promisify(url: @basePath+'/md5', (p) =>
      @authHttp.get(p)
    ).then (r) => r.md5

  # @return A jQuery promise
  get_settings: ->
    @_promisify(url: @basePath, (p) =>
      @authHttp.get(p)
    ).then (r) => JSON.parse(r.settings)

  # @param [Object] settings data to put on sync server.
  # @return A jQuery promise
  post_settings: (settings) ->
    @_promisify(url: @basePath, params: {settings: JSON.stringify(settings)}, (p) =>
      @authHttp.post(p)
    ).then (r) => r.md5

  # @param [Object] settings data to put on sync server.
  # @return A jQuery promise
  put_settings: (settings) ->
    @_promisify(url: @basePath, params: {settings: JSON.stringify(settings)}, (p) =>
      @authHttp.put(p)
    ).then (r) => r.md5

  # @return A jQuery promise
  delete_settings: ->
    @_promisify(url: @basePath, (p) =>
      @authHttp.delete(p)
    )

  # @param [Object] params An object given as argument to fct.
  # @return A jQuery Deferred
  _promisify: (params, fct) ->
    d = $.Deferred()
    fct(_.extend(params, {onSuccess: _.bind(d.resolve,d), onError: _.bind(d.reject,d)}))
    d.promise()
