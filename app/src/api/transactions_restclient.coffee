
class ledger.api.TransactionsRestClient extends ledger.api.RestClient
  @singleton()

  DefaultBatchSize: 20

  getRawTransaction: (transactionHash, callback) ->
    @http().get
      url: "blockchain/#{ledger.config.network.ticker}/transactions/#{transactionHash}/hex"
      onSuccess: (response) ->
        callback?(response.hex)
      onError: @networkErrorCallback(callback)

  getTransactions: (addresses, batchSize, callback) ->
    if _.isFunction(batchSize)
      callback = batchSize
      batchSize = null
    batchSize ?= @DefaultBatchSize
    transactions = []
    _.async.eachBatch addresses, batchSize, (batch, done, hasNext, batchIndex, batchCount) =>
      @http().get
        url: "blockchain/#{ledger.config.network.ticker}/addresses/#{batch.join(',')}/transactions"
        onSuccess: (response) ->
          transactions = transactions.concat(response)
          callback(transactions) unless hasNext
          do done
        onError: @networkErrorCallback(callback)

  createTransactionStreamForAllObservedPaths: ->
    addresses = ledger.wallet.pathsToAddressesStream(ledger.wallet.Wallet.instance.getAllObservedAddressesPaths()).map (e) -> e[1]
    @createTransactionStream(addresses)

  createTransactionStream: (addresses) ->
    highland(addresses)
      .batch(@DefaultBatchSize)
      .consume (err, batch, push, next) =>
        return push null, batch if batch is ledger.stream.nil
        @http().get
          url: "blockchain/#{ledger.config.network.ticker}/addresses/#{batch.join(',')}/transactions"
          onSuccess: (transactions) ->
            push(null, transaction) for transaction in transactions
            do next
          onError: (err) =>
            push(err)
            do next
        .done()
        return

  postTransaction: (transaction, callback) ->
    @http().post
      url: "blockchain/#{ledger.config.network.ticker}/pushtx",
      data: {tx: transaction.getSignedTransaction()}
      onSuccess: (response) ->
        transaction.setHash(response.transaction_hash)
        callback?(transaction)
      onError: @networkErrorCallback(callback)

  postTransactionHex: (txHex, callback) ->
    @http().post
      url: "blockchain/#{ledger.config.network.ticker}/pushtx",
      data: {tx: txHex}
      onSuccess: (response) ->
        callback?(response.transaction_hash)
      onError: @networkErrorCallback(callback)

  refreshTransaction: (transactions, callback) ->
    outTransactions = []
    _.async.each transactions, (transaction, done, hasNext) =>
      @http().get
        url: "blockchain/#{ledger.config.network.ticker}/transactions/#{transaction.get('hash')}"
        onSuccess: (response) =>
          outTransactions.push response
          callback? outTransactions unless hasNext
          do done
        onError: @networkErrorCallback(callback)