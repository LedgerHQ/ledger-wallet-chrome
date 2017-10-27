class ledger.wallet.MultiOutputsTransaction extends ledger.wallet.Transaction

  # @property [Array<Object>]
  outputs: undefined

  # @property [Array<Object>]
  _btOutputs: undefined

  constructor: (@dongle, @fees, @outputs, @inputs, @changePath, @changeAddress, @data) ->
    @createPaymentTransaction = @dongle.createPaymentTransactionMultiOutputs
    @amount = new ledger.Amount()
    for output in @outputs
      @amount = @amount.add(output[1])
    super()


  serialize : ->
    amount: @amount.toSatoshiNumber(),
    address: @outputs,
    fee: @fees.toSatoshiNumber(),
    hash: @hash,
    raw: @getSignedTransaction()


    ###
    Creates a new transaction asynchronously. The created transaction will only be initialized (i.e. it will only retrieve
    a sufficient number of input to perform the transaction)

    @param {ledger.Amount} amount The amount to send (expressed in satoshi)
    @param {ledger.Amount} fees The miner fees (expressed in satoshi)
    @param {String} address The recipient address
    @param {Array<Output>} utxo The list of utxo to sign in order to perform the transaction
    @param {String} changePath The path to use for the change
    @param {String} changeAddress The change address
    @option [Function] callback The callback called once the transaction is created
    @return [Q.Promise] A closure
  ###
  @create: ({fees, outputs, utxo, changePath, changeAddress, data}, callback = null) ->
    d = ledger.defer(callback)
    amount = new ledger.Amount()
    for pair in outputs
      amount = amount.add(pair[1])
    dust = Amount.fromSatoshi(ledger.config.network.dust)
    return d.rejectWithError(Errors.DustTransaction) && d.promise if amount.lte(dust)
    totalUtxoAmount = _(utxo).chain().map((u) -> ledger.Amount.fromSatoshi(u.get('value'))).reduce(((a, b) -> a.add(b)), ledger.Amount.fromSatoshi(0)).value()
    return d.rejectWithError(Errors.NotEnoughFunds) && d.promise if totalUtxoAmount.lt(amount.add(fees))
    # Check if UTXO are safe to spend
    
    #return d.rejectWithError(Errors.No)
    $info("--- CREATE TRANSACTION ---")
    $info("Amount: ", amount.toString())
    $info("Fees: ", fees.toString())
    $info("Total send: ", totalUtxoAmount.toString())
    i = 0
    for pair in outputs
      $info("Address: ", i, pair[0], pair[1].toString())
      ++i
    $info("UTXO: ", utxo)
    $info("Change path: ", changePath)
    $info("Change address: ", changeAddress)
    $info("Data: ", data)

    changeAmount = totalUtxoAmount.subtract(amount.add(fees))
    if changeAmount.lte(dust)
      fees  = totalUtxoAmount.subtract(amount)
      changeAmount = ledger.Amount.fromSatoshi(0)
      $info("Applied fees: ", fees)

    # Get each raw tx
    iterate = (index, inputs) ->
      output = utxo[index]
      return d.resolve(inputs) unless output?
      d = ledger.defer()
      ledger.api.TransactionsRestClient.instance.getRawTransaction output.get('transaction_hash'), (rawTransaction, error) ->
        if error?
          console.log error
          return d.rejectWithError(Errors.NetworkError)
        result = raw: rawTransaction, paths: [output.get('path')], output_index: output.get('index'), value: output.get('value')
        d.resolve(iterate(index + 1, inputs.concat([result])))
      d.promise
    d.resolve(iterate(0, []).then (inputs) =>
      new MultiOutputsTransaction(ledger.app.dongle, fees, outputs, inputs, changePath, changeAddress, data)
    )
    d.promise  