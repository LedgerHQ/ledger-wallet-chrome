
class ledger.api.SyncRestClient extends ledger.api.RestClient

  @instance: new @

  constructor: () ->
    @authHttp = @http().authenticated()

  # @param [Function] cb cb(md5:String) a callback function.
  get_md5: (cb, ecb) ->
    @authHttp.get(url: 'sync/md5', onSuccess: cb, onError: ecb)

  # @param [Function] cb cb(meta:Object, md5:String) a callback function.
  # @param [Function] ecb cb(err:String) an error callback function.
  get_meta: (cb, ecb) ->
    @authHttp.get(url: 'sync/meta', onSuccess: cb, onError: ecb)

  # @param [Object] meta data to put on sync server.
  # @param [Function] cb cb(meta:Object, md5:String) a callback function.
  # @param [Function] ecb cb(err:String) an error callback function.
  put_meta: (meta, cb, ecb) ->
    @authHttp.put(url: 'sync/meta', params: meta, onSuccess: cb, onError: ecb)
