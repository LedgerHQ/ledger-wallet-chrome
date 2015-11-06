class ledger.tasks.TransactionObserverTask extends ledger.tasks.Task

  constructor: () -> super 'global_transaction_observer'

  onStart: () ->
    @_listenNewTransactions()
    @_listenNewTransactionWithVierzonNode()

  onStop: () ->
    @newTransactionStream?.close()
    @newTransactionStreamVierzon?.close()

  _listenNewTransactions: () ->
    @newTransactionStream = new WebSocket "wss://ws.chain.com/v2/notifications"
    @newTransactionStream.onopen = () =>
      @newTransactionStream.send JSON.stringify type: "new-transaction", block_chain: ledger.config.network.ws_chain
      @newTransactionStream.send JSON.stringify type: "new-block", block_chain: ledger.config.network.ws_chain

    @newTransactionStream.onmessage = (event) =>
      data = JSON.parse(event.data)
      return unless data?.payload?.type?
      switch data.payload.type
        when 'new-transaction'
          ledger.tasks.TransactionConsumerTask.instance.pushTransaction(data.payload.transaction)
        when 'new-block'
          @_handleNewBlock data.payload.block
    @newTransactionStream.onclose = => @_listenNewTransactions() if @isRunning()

  _listenNewTransactionWithVierzonNode: () ->
    return
    return unless ledger.config.network is ledger.bitcoin.Networks.bitcoin
    @newTransactionStreamVierzon = io("http://91.121.210.159:3001/")
    @newTransactionStreamVierzon.on 'connect', =>
      @newTransactionStreamVierzon.emit 'subscribe', 'inv'
    @newTransactionStreamVierzon.on 'tx', (data) =>
      l "Received ", data

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