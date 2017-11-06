
class ledger.api.BlockRestClient extends ledger.api.RestClient

  @instance: new @

  constructor: (@ticker = -> ledger.config.network.ticker) ->
    super

  refreshLastBlock: (callback) ->
    @http().get
      url: "blockchain/v2/#{@ticker()}/blocks/current"
      onSuccess: (response) ->
        response['time'] = new Date(response['time'] * 1000)
        block = Block.fromJson(response).save()
        ledger.app.emit 'wallet:operations:update'
        callback?(block)
      onError: @networkErrorCallback(callback)

  getLastBlock: (callback) ->
    @http().get
      url: "blockchain/v2/#{@ticker()}/blocks/current"
      onSuccess: (response) ->
        response['time'] = new Date(response['time'] * 1000)
        callback?(response)
      onError: @networkErrorCallback(callback)
