
class ledger.api.UnspentOutputsRestClient extends ledger.api.RestClient

  getUnspentOutputsFromAddresses: (addresses, callback) ->
    addresses = (address for address in addresses when Bitcoin.Address.validate(address) is true)
    result = []
    _.async.eachBatch addresses, 20, (batch, done, hasNext, batchIndex, batchCount) =>
      @http().get
        url: "blockchain/#{ledger.config.network.ticker}/addresses/#{batch.join(',')}/unspents"
        onSuccess: (response) ->
          result = result.concat(response)
          callback(result) unless hasNext
          do done
        onError: @networkErrorCallback(callback)

  getUnspentOutputsFromPaths: (addressesPaths, callback) ->
    ledger.wallet.pathsToAddresses addressesPaths, (addresses, notFound) =>
      if notFound.length == addressesPaths.length
        callback? null, {title: 'Missing addresses', missings: notFound}
      else
        @getUnspentOutputsFromAddresses _.values(addresses), (outputs, error) =>
          return callback?(null, error) if error?
          paths = _.invert(addresses)
          for output in outputs
            output.paths = []
            output.paths.push paths[address] for address in output.addresses when paths[address]?
          callback?(outputs)

ledger.api.UnspentOutputsRestClient.instance = new ledger.api.UnspentOutputsRestClient()