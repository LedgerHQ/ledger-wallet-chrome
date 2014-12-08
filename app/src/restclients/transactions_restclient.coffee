
class ledger.api.TransactionsRestClient extends ledger.api.RestClient
  @singleton()

  getRawTransaction: (transactionHash, callback) ->
    @http().get
      url: "blockchain/transactions/#{transactionHash}/hex"
      onSuccess: (response) ->
        l response
        callback?(response.hex)
      onError: @networkErrorCallback(callback)

  getTransactions: (addresses, batchSize, callback) ->
    if _.isFunction(batchSize)
      callback = batchSize
      batchSize = null
    batchSize ?= 20
    transactions = []
    _.async.eachBatch addresses, batchSize, (batch, done, hasNext, batchIndex, batchCount) =>
      @http().get
        url: "blockchain/addresses/#{batch.join(',')}/transactions"
        onSuccess: (response) ->
          transactions = transactions.concat(response)
          callback(transactions) unless hasNext
          do done
        onError: @networkErrorCallback(callback)

  postTransaction: (transaction, callback) ->
    @http().postForm
      url: "blockchain/pushtx"
      params: {tx: transaction.getSignedTransaction()}
      onSuccess: (response) ->
        transaction.setHash(response.transaction_hash)
        callback?(transaction)
      onError: @networkErrorCallback(callback)

  refreshTransaction: (transactions, callback) ->
    outTransactions = []
    _.async.each transactions, (transaction, done, hasNext) =>
      @http().get
        url: '/blockchain/transactions/#{transaction.hash}'
        onSuccess: (response) =>
          outTransactions.push  response
          callback? response unless hasNext
          do done
        onError: @networkErrorCallback(callback)