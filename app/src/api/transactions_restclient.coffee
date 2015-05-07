
class ledger.api.TransactionsRestClient extends ledger.api.RestClient
  @singleton()

  getRawTransaction: (transactionHash, callback) ->
    @http().get
      url: "blockchain/transactions/#{transactionHash}/hex"
      onSuccess: (response) ->
        callback?(response.hex)
      onError: @networkErrorCallback(callback)

  getTransactions: (addresses, batchSize, callback) ->
    if _.isFunction(batchSize)
      callback = batchSize
      batchSize = null
    batchSize ?= 200
    transactions = []
    _.async.eachBatch addresses, batchSize, (batch, done, hasNext, batchIndex, batchCount) =>
      @http().get
        url: "blockchain/addresses/#{batch.join(',')}/transactions"
        onSuccess: (response) ->
          transactions = transactions.concat(response)
          callback(transactions) unless hasNext
          do done
        onError: @networkErrorCallback(callback)

  createTransactionStream: (addresses) ->
    stream = new Stream()
    stream.onOpen = =>
      _.async.eachBatch addresses, 200, (batch, done, hasNext) =>
        @http().get
          url: "blockchain/addresses/#{batch.join(',')}/transactions"
          onSuccess: (transactions) ->
            stream.write(transaction) for transaction in transactions
            stream.close() unless hasNext
            do done
          onError: =>
            stream.error 'Network Error'
            stream.close()
    stream

  postTransaction: (transaction, callback) ->
    @http().post
      url: "blockchain/pushtx",
      data: {tx: transaction.getSignedTransaction()}
      onSuccess: (response) ->
        transaction.setHash(response.transaction_hash)
        callback?(transaction)
      onError: @networkErrorCallback(callback)

  postTransactionHex: (txHex, callback) ->
    @http().post
      url: "blockchain/pushtx",
      data: {tx: txHex}
      onSuccess: (response) ->
        callback?(response.transaction_hash)
      onError: @networkErrorCallback(callback)

  refreshTransaction: (transactions, callback) ->
    outTransactions = []
    _.async.each transactions, (transaction, done, hasNext) =>
      @http().get
        url: "blockchain/transactions/#{transaction.get('hash')}"
        onSuccess: (response) =>
          outTransactions.push response
          callback? outTransactions unless hasNext
          do done
        onError: @networkErrorCallback(callback)