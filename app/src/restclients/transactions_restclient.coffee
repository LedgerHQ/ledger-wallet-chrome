
class ledger.api.TransactionsRestClient extends ledger.api.RestClient
  @singleton()

  getRawTransaction: (transactionHash, callback) ->
    @http().get
      url: "blockchain/transactions/#{transactionHash}/hex"
      onSuccess: (response) ->
        callback?(response.hex)
      onError: @networkErrorCallback(callback)

  getTransactions: (addresses, callback) ->
    transactions = []
    _.async.eachBatch addresses, 20, (batch, done, hasNext) =>
      @http().get
        url: "blockchain/addresses/#{batch.join(',')}/transactions"
        onSuccess: (response) ->
          transactions = transactions.concat(response)
          callback(transactions) unless hasNext is true
          do done
        onFailure: @networkErrorCallback(callback)


  postTransaction: (transaction, callback) ->
    @http().post
      url: "blockchain/transactions/send"
      params: {signed_hex: transaction.getSignedTransaction()}
      onSuccess: (response) ->
        transaction.setHash(response.transaction_hash)
        callback?(transaction)
      onError: @networkErrorCallback(callback)

