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

    @newTransactionStream.onmessage = (event) =>
      data = JSON.parse(event.data)
      if data?.payload.transaction?
        transaction = data.payload.transaction
        @_handleTransactionIO(transaction, transaction.inputs)
        @_handleTransactionIO(transaction, transaction.outputs)
    @newTransactionStream.onclose = => @_listenNewTransactions() if @isRunning()

  _handleTransactionIO: (transaction, io) ->
    found = no
    if io?
      for input in io
        continue unless input.addresses?
        for address in input.addresses
          derivation = ledger.wallet.HDWallet.instance?.cache?.getDerivationPath(address)
          if derivation?
            l derivation
            account = ledger.wallet.HDWallet.instance?.getAccountFromDerivationPath(derivation)
            if account?
              account.shiftCurrentPublicAddressPath() if account.getCurrentPublicAddressPath() == derivation
              account.shiftCurrentChangeAddressPath() if account.getCurrentChangeAddressPath() == derivation
              Account.fromHDWalletAccount(account)?.addRawTransaction transaction, () =>
                ledger.app.emit('wallet:transactions:new')
    found

  @instance: new @()