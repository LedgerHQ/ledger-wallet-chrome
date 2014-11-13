
class ledger.api.UnspentOutputsRestClient extends ledger.api.RestClient

  getUnspentOutputsFromAddresses: (addresses, callback) ->
    query = addresses.join(',')
    @http().get "blockchain/addresses/#{query}/unspents", null,
      (response, request) =>
        l response
      ,
      (xhr, status, message) =>
        callback(null, {xhr, status, message})

  getUnspentOutputsFromPublicAddresses: (accountPath, callback) ->

  getUnspentOutputsFromChangeAddresses: (accountPath, callback) ->

  getUnspentOutputsFromAllAddresses: (accountPath, callback) ->

  getUnspentOutputsFromPaths: (addressesPaths, callback) ->
    ledger.wallet.pathsToAddresses addressesPaths, (addresses, notFound) ->
      if notFound.length > 0
        callback null, {title: 'Missing addresses', missings: notFound}
      else
        @getUnspentOutputsFromAddresses(_.values(addresses), callback)

ledger.api.UnspentOutputsRestClient.instance = new ledger.api.UnspentOutputsRestClient()