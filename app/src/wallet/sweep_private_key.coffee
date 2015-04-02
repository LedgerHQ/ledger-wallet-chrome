@ledger.wallet ?= {}

_.extend ledger.wallet,

  sweepPrivateKey: ({privateKey, account, txFee}, callback) ->
    txFee ?= 10000
    completion = new CompletionClosure(callback)
    recipientAddress = account.getHDAccount().getCurrentPublicAddress()
    ecKey = new window.bitcoin.ECKey.fromWIF(privateKey)
    publicKey = ecKey.pub.getAddress().toString()
    addresses = [publicKey]

    ledger.api.UnspentOutputsRestClient.instance.getUnspentOutputsFromAddresses addresses , (outputs, error) ->
      return completion.failure(error) if error?

      txBuilder = new window.bitcoin.TransactionBuilder()
      amountToSend = new ledger.wallet.Value()

      _.async.each outputs, (output, done, hasNext) ->
        amountToSend = amountToSend.add output.value
        txBuilder.addInput(output.transaction_hash, output.output_index)

        if hasNext is false and amountToSend.lte(txFee)
          # Not enough available funds
          completion.failure(new ledger.StandardError(ledger.errors.NotEnoughFunds))
        else if hasNext is false
          amountToSend = amountToSend.subtract(10000)
          txBuilder.addOutput(recipientAddress, amountToSend.toNumber())

          txBuilder.sign(index, ecKey) for input, index in txBuilder.tx.ins
          txHex = txBuilder.build().toHex()
          ledger.api.TransactionsRestClient.instance.postTransactionHex txHex, (txHash, error) =>
            completion.complete(txHash, error)
        else
          # Continue to collect funds
          do done
    completion.readonly()