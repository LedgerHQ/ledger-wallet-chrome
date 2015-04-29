class ledger.tasks.TransactionObserverTask extends ledger.tasks.Task

  constructor: () -> super 'global_transaction_observer'

  onStart: () ->
    @_listenNewTransactions()

  onStop: () ->
    @newTransactionStream.close()

  _listenNewTransactions: () ->
    @newTransactionStream = new WebSocket "wss://ws.chain.com/v2/notifications"
    @newTransactionStream.onopen = () =>
      @newTransactionStream.send JSON.stringify type: "new-transaction", block_chain: "bitcoin"
      @newTransactionStream.send JSON.stringify type: "new-block", block_chain: "bitcoin"

    @newTransactionStream.onmessage = (event) =>
      data = JSON.parse(event.data)
      return unless data?.payload?.type?
      switch data.payload.type
        when 'new-transaction'
          transaction = data.payload.transaction
          @_handleTransactionIO(transaction, transaction.inputs)
          @_handleTransactionIO(transaction, transaction.outputs)
        when 'new-block'
          @_handleNewBlock data.payload.block
    @newTransactionStream.onclose = => @_listenNewTransactions() if @isRunning()

  _handleTransactionIO: (transaction, io) ->
    found = no
    if io?
      for input in io
        continue unless input.addresses?
        for address in input.addresses
          derivation = ledger.wallet.HDWallet.instance?.cache?.getDerivationPath(address)
          if derivation?
            @logger().info "New transaction on #{derivation}"
            account = ledger.wallet.HDWallet.instance?.getAccountFromDerivationPath(derivation)
            if account?
              @logger().info 'Add transaction'
              account.notifyPathsAsUsed(derivation)
              Account.fromHDWalletAccount(account)?.addRawTransactionAndSave transaction
              Wallet.instance?.retrieveAccountsBalances()
              ledger.tasks.WalletLayoutRecoveryTask.instance.startIfNeccessary()
              ledger.app.emit 'wallet:operations:new'
              ledger.app.emit 'wallet:operations:new'
            else
              @logger().warn "Failed to retrieve an account for #{derivation} ", transaction
    found

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