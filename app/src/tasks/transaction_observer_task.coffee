class ledger.tasks.TransactionObserverTask extends ledger.tasks.Task

  constructor: () -> super 'global_transaction_observer'

  onStart: () ->
    @_listenNewTransactions()

  onStop: () ->
    @newTransactionStream?.close()

  _listenNewTransactions: () ->
    @newTransactionStream = new WebSocket "wss://ws.ledgerwallet.com/blockchain/v2/btc/ws"

    @newTransactionStream.onmessage = (event) =>
      data = JSON.parse(event.data)
      return unless data?.payload?.type?
      switch data.payload.type
        when 'new-transaction'
          #l "Received transaction ", data.payload.transaction?.hash
          ledger.tasks.TransactionConsumerTask.instance.pushTransaction(data.payload.transaction)
        when 'new-block'
          @_handleNewBlock data.payload.block
    @newTransactionStream.onclose = => @_listenNewTransactions() if @isRunning()

  _handleNewBlock: (block) ->
    @logger().trace 'Receive new block'
    json =
      hash: block['hash']
      height: block['height']
      time: new Date(block['time'])
    block = Block.fromJson(json).save()
    for transactionHash in block['transaction_hashes']
      txs = Transaction.find(hash: transactionHash).data()
      if txs.length > 0
        @logger().trace 'Found transaction in block'
        for tx in txs
          block.add('transactions', tx)
    block.save()
    ledger.tasks.WalletLayoutRecoveryTask.instance.startIfNeccessary()
    ledger.app.emit 'wallet:operations:update'

  @instance: new @()

  @reset: () ->
    @instance = new @