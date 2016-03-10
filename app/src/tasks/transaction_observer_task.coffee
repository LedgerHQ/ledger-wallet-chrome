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
    Block.fromJson(json).save()
    ledger.app.emit 'wallet:operations:update'
    for transactionHash in block['transaction_hashes']
      if Transaction.find(hash: transactionHash).count() > 0
        @logger().trace 'Found transaction in block'
        ledger.tasks.WalletLayoutRecoveryTask.instance.startIfNeccessary()
        return

  @instance: new @()

  @reset: () ->
    @instance = new @