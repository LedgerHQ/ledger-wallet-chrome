
class ledger.api.SyncRestClient extends ledger.api.AuthRestClient

  # Create a single instance of a SyncRestClient for a same addr
  @_instances: {}
  @instance: (addr) ->
    @_instances[addr] ||= new @(addr)

  constructor: (addr) ->
    super
    @basePath = "accountsettings/#{addr}"

  # @param [Function] cb A callback function with object.md5 as argument.
  # @return A promise
  get_settings_md5: ->
    @http().get(url: @basePath+'/md5').then (r) => r.md5

  # @return A promise
  get_settings: ->
    @http().get(url: @basePath).then (r) => JSON.parse(r.settings)

  # @param [Object] settings data to put on sync server.
  # @return A promise
  post_settings: (settings) ->
    @http().post(url: @basePath, data: {settings: JSON.stringify(settings)}).then (r) => r.md5

  # @param [Object] settings data to put on sync server.
  # @return A promise
  put_settings: (settings) ->
    @http().put(url: @basePath, data: {settings: JSON.stringify(settings)}).then (r) => r.md5

  # @return A promise
  delete_settings: ->
    @http().delete(url: @basePath)
