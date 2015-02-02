
class ledger.api.TransactionsRestClient extends ledger.api.RestClient
  @singleton()

  getRawTransaction: (transactionHash, callback) ->
    @http.get(
      url: "blockchain/transactions/#{transactionHash}/hex"
    ).done( (response) ->
      l response
      callback?(response.hex)
    ).fail(@networkErrorCallback(callback))

  getTransactions: (addresses, batchSize, callback) ->
    if _.isFunction(batchSize)
      callback = batchSize
      batchSize = null
    batchSize ?= 20
    transactions = []
    _.async.eachBatch addresses, batchSize, (batch, done, hasNext, batchIndex, batchCount) =>
      @http.get(
        url: "blockchain/addresses/#{batch.join(',')}/transactions"
      ).done( (response) ->
        transactions = transactions.concat(response)
        callback(transactions) unless hasNext
        do done
      ).fail(@networkErrorCallback(callback))

  createTransactionStream: (addresses) ->
    stream = new Stream()
    stream.onOpen = =>
      _.async.eachBatch addresses, 20, (batch, done, hasNext) =>
        @http.get(
          url: "blockchain/addresses/#{batch.join(',')}/transactions"
        ).done( (transactions) ->
          stream.write(transaction) for transaction in transactions
          stream.close() unless hasNext
          do done
        ).fail =>
          stream.error 'Network Error'
          stream.close()
    stream

  postTransaction: (transaction, callback) ->
    @http.postForm(
      url: "blockchain/pushtx",
      data: {tx: transaction.getSignedTransaction()}
    ).done( (response) ->
      transaction.setHash(response.transaction_hash)
      callback?(transaction)
    ).fail @networkErrorCallback(callback)

  refreshTransaction: (transactions, callback) ->
    outTransactions = []
    _.async.each transactions, (transaction, done, hasNext) =>
      @http.get(
        url: "blockchain/transactions/#{transaction.get('hash')}"
      ).done( (response) =>
        outTransactions.push response
        callback? outTransactions unless hasNext
        do done
      ).fail @networkErrorCallback(callback)