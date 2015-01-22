
class ledger.api.SyncRestClient extends ledger.api.RestClient

  @instance: new @

  constructor: (addr) ->
    @authHttp = @http().authenticated()
    @basePath = 'accountsettings/#{addr}'

  # @param [Function] cb A callback function with object.md5 as argument.
  get_settings_md5: (cb, ecb) ->
    @authHttp.get(url: @basePath+'/md5', onSuccess: cb, onError: ecb)

  # @param [Function] cb cb(settings:Object) a callback function.
  # @param [Function] ecb An ajax error callback function.
  get_settings: (cb, ecb) ->
    @authHttp.get(url: @basePath, onSuccess: cb, onError: ecb)

  # @param [Object] settings data to put on sync server.
  # @param [Function] cb A callback function with object.md5 as argument.
  # @param [Function] ecb An ajax error callback function.
  post_settings: (settings, cb, ecb) ->
    @authHttp.post(url: @basePath, params: settings, onSuccess: cb, onError: ecb)

  # @param [Object] settings data to put on sync server.
  # @param [Function] cb A callback function with object.md5 as argument.
  # @param [Function] ecb An ajax error callback function.
  put_settings: (settings, cb, ecb) ->
    @authHttp.put(url: @basePath, params: settings, onSuccess: cb, onError: ecb)

  # @param [Function] cb A callback function.
  # @param [Function] ecb An ajax error callback function.
  delete_settings: (cb, ecb) ->
    @authHttp.delete(url: @basePath, onSuccess: cb, onError: ecb)
