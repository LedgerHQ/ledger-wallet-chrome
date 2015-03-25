
class ledger.api.SyncRestClient extends ledger.api.AuthRestClient

  # Create a single instance of a SyncRestClient for a same addr
  @_instances: {}
  @instance: (addr) ->
    @_instances[addr] ||= new @(addr)

  constructor: (addr) ->
    super
    @basePath = "accountsettings/#{addr}"

  # @param [Function] cb A callback function with object.md5 as argument.
  # @return A jQuery promise
  get_settings_md5: ->
    Q(@http().get(url: @basePath+'/md5')).then (r) => r.md5

  # @return A jQuery promise
  get_settings: ->
    Q(@http().get(url: @basePath)).then (r) => JSON.parse(r.settings)

  # @param [Object] settings data to put on sync server.
  # @return A jQuery promise
  post_settings: (settings) ->
    Q(@http().post(url: @basePath, data: {settings: JSON.stringify(settings)})).then (r) => r.md5

  # @param [Object] settings data to put on sync server.
  # @return A jQuery promise
  put_settings: (settings) ->
    Q(@http().put(url: @basePath, data: {settings: JSON.stringify(settings)})).then (r) => r.md5

  # @return A jQuery promise
  delete_settings: ->
    Q(@http().delete(url: @basePath))
