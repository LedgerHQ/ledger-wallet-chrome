
window.ledger ?= {}
ledger.bitcoin ?= {}

gatherAllUnconfirmedTransactions = (client, rootTxHash, txs = [], deffer = ledger.defer()) ->
  p = client.getTransactionByHash(rootTxHash).then (transaction) ->
    if transaction["block"]?
      txs
    else
      txs.push(transaction)
      Q.all(gatherAllUnconfirmedTransactions(client, input["output_hash"]) for input in transaction["inputs"]).then (unconfirmed) ->
        unconfirmed = _.flatten(unconfirmed)
        txs = txs.concat(unconfirmed)
        txs
  deffer.resolve(p)
  deffer.promise

extendTransactionWithSize = (client, tx) ->
  client.getTransactionSize(tx["hash"]).then (size) ->
    tx.size = size
    tx

ledger.bitcoin.cpfp =

  fetchUnconfirmedTransactions: (rootTxHash) ->
    client = new ledger.api.TransactionsRestClient()
    gatherAllUnconfirmedTransactions(client, rootTxHash).then (transactions) ->
      throw ledger.errors.new(ledger.errors.TransactionNotEligible) if !ledger.bitcoin.cpfp.isEligibleToCpfp(rootTxHash)
      if transactions.length is 0
        throw ledger.errors.new(ledger.errors.TransactionAlreadyConfirmed)
      Q.all(extendTransactionWithSize(client, tx) for tx in transactions)
    .then (transactions) ->
      # We have every unconfirmed transactions with their associated size, we need to compute the total size (of all transactions)
      # and the total associated fee. Finally compute a fee sufficient to support the size of all transaction plus the size of CPFP
      # transaction.
      totalSize = ledger.Amount.fromSatoshi(0)
      totalFees = ledger.Amount.fromSatoshi(0)
      for transaction in transactions
        totalSize = totalSize.add(transaction.size)
        totalFees = totalFees.add(transaction.fees)
      {transactions: transactions, size: totalSize, fees: totalFees}


  isEligibleToCpfp: (rootTxHash) ->
    return no if Input.find(previous_tx: rootTxHash).data().length ? 0
    for output in Output.find(transaction_hash: rootTxHash).data()
      if !_.isEmpty(output.get("path"))
        return yes
    return no

  createTransaction: (account, rootTxHash, fees) ->
    utxo = _(account.getUtxo()).sortBy (o) -> o.get('transaction').get('confirmations')
    findUtxo = (hash) ->
      for output in utxo
        return output if output.get("transaction_hash")
    ledger.tasks.FeesComputationTask.instance.update().then ->
      if fees?
        if !fees.gt(0)
          #feePerByte = ledger.tasks.FeesComputationTask.instance.getFeesForNumberOfBlocks(1) / 1000
          throw ledger.errors.new(ledger.errors.WrongFeesFormat)
        feePerByte = fees
      else
        feePerByte = ledger.tasks.FeesComputationTask.instance.getFeesForNumberOfBlocks(1) / 1000
      ledger.bitcoin.cpfp.fetchUnconfirmedTransactions(rootTxHash).then (unconfirmed) ->
        # Coin selection
        inputs = []
        hasInput = (input) ->
          for i in inputs
            if input.get("transaction_hash") == i.get("transaction_hash") and input.get("index") == i.get("index")
              return yes
          return no
        inputs.push(findUtxo(unconfirmed.transactions[0]["hash"]))
        collectedAmount = ledger.Amount.fromSatoshi(inputs[0].get("value"))
        index = 0
        while on
          totalSize = unconfirmed.size.add(ledger.bitcoin.estimateTransactionSize(inputs.length, 2).max)
          feeAmount = totalSize.multiply(feePerByte).subtract(unconfirmed.fees)
          if collectedAmount.gte(feeAmount) && collectedAmount.gte(5430)
            return {unconfirmed, inputs, collectedAmount, fees: feeAmount, size: totalSize}
          input = utxo[index]
          if input? and !hasInput(input)
            inputs.push(input)
            collectedAmount = collectedAmount.add(ledger.Amount.fromSatoshi(input.get("value")))
          index += 1
          break if not input?
        throw ledger.errors.new(ledger.errors.NotEnoughFunds)
    .then (preparedTransaction) ->
      if !preparedTransaction.fees.gte(1)
        throw ledger.errors.new(ledger.errors.FeesTooLowCpfp, '', preparedTransaction)
      preparedTransaction.amount = preparedTransaction.collectedAmount.subtract(preparedTransaction.fees)
      preparedTransaction
