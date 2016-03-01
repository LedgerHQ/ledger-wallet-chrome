
class ledger.api.BlockRestClient extends ledger.api.RestClient

  @instance: new @

  refreshLastBlock: (callback) ->
    @http().get
      url: "blockchain/v2/#{ledger.config.network.ticker}/blocks/current"
      onSuccess: (response) ->
        response['time'] = new Date(response['time'] * 1000)
        block = Block.fromJson(response).save()
        ledger.app.emit 'wallet:operations:update'
        callback?(block)
      onError: @networkErrorCallback(callback)