class ledger.tasks.TransactionObserverTask extends ledger.tasks.Task

  constructor: () -> super 'global_transaction_observer'

  onStart: () ->
    @_listenNewTransactions()

  onStop: () ->
    @newTransactionStream?.close()

  _listenNewTransactions: () ->
    @newTransactionStream = new WebSocket "wss://ws.ledgerwallet.com/blockchain/btc/ws"

    @newTransactionStream.onmessage = (event) =>
      data = JSON.parse(event.data)
      return unless data?.payload?.type?
      switch data.payload.type
        when 'new-transaction'
          ledger.tasks.TransactionConsumerTask.instance.pushTransaction(data.payload.transaction)
        when 'new-block'
          @_handleNewBlock data.payload.block
    @newTransactionStream.onclose = => @_listenNewTransactions() if @isRunning()

  _handleNewBlock: (block) ->
    @logger().trace 'Receive new block'
    for transactionHash in block['transaction_hashes']
      if Operation.find(hash: transactionHash).count() > 0
        @logger().trace 'Found transaction in block'
        if ledger.tasks.OperationsSynchronizationTask.instance.isRunning()
          ledger.tasks.OperationsSynchronizationTask.instance.synchronizeConfirmationNumbers()
        else
          ledger.tasks.OperationsSynchronizationTask.instance.startIfNeccessary()
        Wallet.instance?.retrieveAccountsBalances()
        return

  @instance: new @()

  @reset: () ->
    @instance = new @