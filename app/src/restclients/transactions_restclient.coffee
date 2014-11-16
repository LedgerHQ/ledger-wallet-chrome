
class ledger.api.TransactionsRestClient extends ledger.api.RestClient
  @singleton()

  getRawTransaction: (transactionHash, callback) ->
    @http().get
      url: "blockchain/transactions/#{transactionHash}/hex"
      onSuccess: (response) ->
        callback?(response.hex)
      onError: @errorCallback(callback)

  postTransaction: (transaction, callback) ->
    @http().post
      url: "blockchain/transactions/send"
      params: {signed_hex: transaction.getSignedTransaction()}
      onSuccess: (response) ->
        transaction.setHash(response.transaction_hash)
        callback?(transaction)
      onError: @errorCallback(callback)

