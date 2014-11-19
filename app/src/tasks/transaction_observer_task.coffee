class ledger.tasks.TransactionObserverTask extends ledger.tasks.Task

  constructor: () -> super 'global_transaction_observer'

  onStart: () ->
    @_listenNewTransactions()
    @_listenTransactions()

  onStop: () ->
    @newTransactionStream.close()

  _listenNewTransactions: () ->
    @newTransactionStream = new WebSocket "wss://ws.chain.com/v2/notifications"
    @newTransactionStream.onopen = (event) =>
      @newTransactionStream.send JSON.stringify type: "new-transaction", block_chain: "bitcoin"

    @newTransactionStream.onmessage = (event) =>
      data = JSON.parse(event.data)
      if data?.payload.transaction?
        transaction = data.payload.transaction

        for input in transaction.inputs
          for address in input.addresses
            derivation = ledger.wallet.HDWallet.instance?.cache?.getDerivationPath(address)
            l derivation if derivation?

        for output in transaction.outputs
          for address in output.addresses
            derivation = ledger.wallet.HDWallet.instance?.cache?.getDerivationPath(address)
            l derivation if derivation?

    @newTransactionStream.onclose = => @_listenNewTransactions() if @isRunning()


  _listenTransactions: () ->



  @instance: new @()