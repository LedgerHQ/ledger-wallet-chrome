@ledger.wallet ?= {}


_.extend ledger.wallet,

  sweepPrivateKey: (privateKey, account) ->
      txFee = 10000
      recipientAddress = account.getHDAccount().getCurrentPublicAddress() # Todo : check this line
      ecKey = new window.bitcoin.ECKey.fromWIF(privateKey)
      publicKey = ecKey.pub.getAddress().toString()
      addresses = [publicKey]

      ledger.api.UnspentOutputsRestClient.instance.getUnspentOutputsFromAddresses addresses , (outputs, error) ->
        return callback?(null, {title: 'Network Error', error, code: ledger.errors.NetworkError}) if error?

        txBuilder = new window.bitcoin.TransactionBuilder()
        amountToSend = new ledger.wallet.Value()

        _.async.each outputs, (output, done, hasNext) ->
          amountToSend = amountToSend.add output.value
          txBuilder.addInput(output.transaction_hash, output.output_index)

          if hasNext is false and amountToSend.lte(txFee)
            # Not enough available funds
            callback?(null, {title: 'Not enough funds', code: ledger.errors.NotEnoughFunds})
          else if hasNext is false
            amountToSend = amountToSend.subtract(10000)
            txBuilder.addOutput(recipientAddress, amountToSend.toNumber())

            txBuilder.sign(index, ecKey) for input, index in txBuilder.tx.ins
            txHex = txBuilder.build().toHex()
            console.log(txHex)
            ledger.api.TransactionsRestClient.instance.postTransactionHex txHex, (txHash, error) =>
              if error? # Todo : handling errors
                console.log(error)
              else
                console.log(txHash)
          else
            # Continue to collect funds
            do done