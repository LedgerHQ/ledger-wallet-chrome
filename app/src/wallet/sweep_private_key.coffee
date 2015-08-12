@ledger.wallet ?= {}

_.extend ledger.wallet,

  sweepPrivateKey: ({privateKey, account, txFee}, callback) ->
    txFee ?= ledger.preferences.instance.getMiningFee()
    d = ledger.defer(callback)
    recipientAddress = account.getHDAccount().getCurrentPublicAddress()
    ecKey = new window.bitcoin.ECKey.fromWIF(privateKey)
    publicKey = ecKey.pub.getAddress().toString()
    addresses = [publicKey]

    ledger.api.UnspentOutputsRestClient.instance.getUnspentOutputsFromAddresses addresses , (outputs, error) ->
      return d.reject(error) if error?

      txBuilder = new window.bitcoin.TransactionBuilder()
      amountToSend = new ledger.Amount()

      _.async.each outputs, (output, done, hasNext) ->
        amountToSend = amountToSend.add output.value
        txBuilder.addInput(output.transaction_hash, output.output_index)

        if hasNext is false and amountToSend.lte(txFee)
          # Not enough available funds
          d.rejectWithError(ledger.errors.NotEnoughFunds)
        else if hasNext is false
          amountToSend = amountToSend.subtract(10000)
          txBuilder.addOutput(recipientAddress, amountToSend.toNumber())

          txBuilder.sign(index, ecKey) for input, index in txBuilder.tx.ins
          txHex = txBuilder.build().toHex()
          ledger.api.TransactionsRestClient.instance.postTransactionHex txHex, (txHash, error) =>
            d.resolve(txHash, error)
        else
          # Continue to collect funds
          do done
    d.promise
