
class ledger.api.SyncRestClient extends ledger.api.AuthRestClient

  # Create a single instance of a SyncRestClient for a same addr
  @_instances: {}
  @instance: (addr) ->
    @_instances[addr] ||= new @(addr)

  constructor: (addr) ->
    super
    @chain=''
    if ledger.config.network.name != 'bitcoin' and (ledger.config.network.bip44_coin_type == '0' or ledger.config.network.bip44_coin_type == '145')
      @chain = '?chain=' + ledger.config.network.name
    @basePath = "accountsettings/#{addr}"

  # @param [Function] cb A callback function with object.md5 as argument.
  # @return A promise
  get_settings_md5: ->
    @http().get(url: @basePath+'/md5'+@chain).then (r) => r.md5

  # @return A promise
  get_settings: ->
    @http().get(url: @basePath+@chain).then (r) => JSON.parse(r.settings)

  # @param [Object] settings data to put on sync server.
  # @return A promise
  post_settings: (settings) ->
    @http().post(url: @basePath+@chain, data: {settings: settings}).then (r) => r.md5

  # @param [Object] settings data to put on sync server.
  # @return A promise
  put_settings: (settings) ->
    @http().put(url: @basePath+@chain, data: {settings: settings}).then (r) => r.md5

  # @return A promise
  delete_settings: ->
    @http().delete(url: @basePath+@chain)

  @reset: ->
    @_instances = {}  
