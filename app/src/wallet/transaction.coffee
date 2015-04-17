ValidationModes =
    PIN: 0x01
    KEYCARD: 0x02
    SECURE_SCREEN: 0x03

Errors = @ledger.errors

Amount = ledger.Amount

@ledger.wallet ?= {}

###
@example Usage
  amount = ledger.Amount.fromBtc("1.234")
  fee = ledger.Amount.fromBtc("0.0001")
  recipientAddress = "1DR6p2UVfu1m6mCU8hyvh5r6ix3dJEPMX7"
  ledger.wallet.Transaction.createAndPrepareTransaction(amount, fees, recipientAddress, inputsAccounts, changeAccount).then (tx) =>
    console.log("Prepared tx :", tx)
###
class ledger.wallet.Transaction
  Transaction = @

  #
  @ValidationModes: ValidationModes
  #
  @DEFAULT_FEES: Amount.fromBits(100)
  #
  @MINIMUM_CONFIRMATIONS: 1
  #
  @MINIMUM_OUTPUT_VALUE: Amount.fromSatoshi(5430)
  #
  @_logger: -> ledger.utils.Logger.getLoggerByTag("Transaction")

  # @property [ledger.Amount]
  amount: undefined
  # @property [ledger.Amount]
  fees: @DEFAULT_FEES
  # @property [String]
  recipientAddress: undefined
  # @property [Array<Object>]
  inputs: undefined
  # @property [String]
  changePath: undefined
  # @property [String]
  hash: undefined
  # @property [String]
  authorizationPaired: undefined


  # @property [Boolean]
  _isValidated: no
  # @property [Object]
  _resumeData: undefined
  # @property [Integer]
  _validationMode: undefined
  # @property [Array<Object>]
  _btInputs: undefined
  # @property [Array<Object>]
  _btcAssociatedKeyPath: undefined
  # @property [String] hex encoded
  _signedRawTransaction: undefined

  # @param [ledger.dongle.Dongle] dongle
  # @param [ledger.Amount] amount
  # @param [ledger.Amount] fees
  # @param [String] recipientAddress
  constructor: (@dongle, @amount, @fees, @recipientAddress, @inputs, @changePath) ->
    @_btInputs = []
    @_btcAssociatedKeyPath = []
    for input in inputs
      splitTransaction = @dongle.splitTransaction(input)
      @_btInputs.push [splitTransaction, input.output_index]
      @_btcAssociatedKeyPath.push input.paths[0]

  # @return [Boolean]
  isValidated: () -> @_isValidated

  # @return [String]
  getSignedTransaction: () -> @_signedRawTransaction

  # @return [Integer]
  getValidationMode: () -> @_validationMode

  # @return [ledger.Amount]
  getAmount: () -> @amount

  # @return [String]
  getRecipientAddress: () -> @receiverAddress

  # @param [String] hash
  setHash: (hash) -> @hash = hash

  serialize: ->
    amount: @amount.toSatoshiNumber(),
    address: @receiverAddress,
    fee: @fees.toSatoshiNumber(),
    hash: @hash,
    raw: @getSignedTransaction()

  # Retrieve information that need to be confirmed by the user.
  # @return [Object]
  #   @option [Integer] validationMode
  #   @option [Object, undefined] amount
  #     @option [String] text
  #     @option [Array<Integer>] indexes
  #   @option [Object] recipientsAddress
  #     @option [String] text
  #     @option [Array<Integer>] indexes
  #   @option [String] validationCharacters
  #   @option [Boolean] needsAmountValidation
  getValidationDetails: ->
    details =
      validationMode: @_validationMode
      recipientsAddress:
        text: @recipientAddress
        indexes: (parseInt(i,16) for i in @_resumeData.indexesKeyCard.match(/../g))
      needsAmountValidation: false
    if @_validationMode is ledger.wallet.Transaction.ValidationModes.SECURE_SCREEN
      length = details.recipientsAddress.indexes.shift()
      details.recipientsAddress.indexes = details.recipientsAddress.indexes.slice(0, length)
    details.validationCharacters = (@recipientAddress[idx] for idx in details.recipientsAddress.indexes)

    # ~> 1.4.13 need validation on amount
    if @dongle.getIntFirmwareVersion() < ledger.dongle.Firmware.V1_4_13
      stringifiedAmount = @amount.toString()
      stringifiedAmount = _.str.lpad(stringifiedAmount, 9, '0')
      # Split amount in integer and decimal parts
      integerPart = stringifiedAmount.substr(0, stringifiedAmount.length - 8)
      decimalPart = stringifiedAmount.substr(stringifiedAmount.length - 8)
      # Prepend to validationCharacters first digit of integer part,
      # and 3 first digit of decimal part only if not empty.
      amountChars = [integerPart.charAt(integerPart.length - 1)]
      if decimalPart isnt "00000000"
        amountChars.concat decimalPart.substring(0,3).split('')
      details.validationCharacters = amountChars.concat(details.validationCharacters)
      # Compute amount indexes
      firstIdx = integerPart.length - 1
      lastIdx = if decimalPart is "00000000" then firstIdx else firstIdx+3
      detail.amount =
        text: stringifiedAmount
        indexes: [firstIdx..lastIdx]
      details.needsAmountValidation = true

    return details

  # @param [Array<Object>] inputs
  # @param [String] changePath
  # @param [Function] callback
  # @return [Q.Promise]
  prepare: (callback=undefined) ->

    # Mock
    txb = new bitcoin.TransactionBuilder()

    rawTxs = for input in @_btInputs
      [splittedTx, outputIndex] = input
      rawTxBuffer = splittedTx.version
      rawTxBuffer = rawTxBuffer.concat(new ByteString(Convert.toHexByte(splittedTx.inputs.length), HEX))
      for input in splittedTx.inputs
        rawTxBuffer = rawTxBuffer.concat(input.prevout).concat(new ByteString(Convert.toHexByte(input.script.length), HEX)).concat(input.script).concat(input.sequence)
      rawTxBuffer = rawTxBuffer.concat(new ByteString(Convert.toHexByte(splittedTx.outputs.length), HEX))
      for output in splittedTx.outputs
        rawTxBuffer = rawTxBuffer.concat(output.amount).concat(new ByteString(Convert.toHexByte(output.script.length), HEX)).concat(output.script)
      rawTxBuffer = rawTxBuffer.concat(splittedTx.locktime)
      [rawTxBuffer, outputIndex]

    values = []
    balance = Bitcoin.BigInteger.valueOf(0)

    for [rawTx, outputIndex] in rawTxs
      tx = bitcoin.Transaction.fromHex(rawTx.toString())
      txb.addInput(tx, outputIndex)
      values.push(tx.outs[outputIndex].value)
    for val, i in values
      balance = balance.add Bitcoin.BigInteger.valueOf(val)

    change = (balance.toString() - @fees.toSatoshiNumber()) - @amount.toSatoshiNumber()

    l balance
    l @amount
    l @fees

    # Get Hash from base58
    arr = ledger.crypto.Base58.decode(@recipientAddress)
    buffer = JSUCrypt.utils.byteArrayToHexStr(arr)
    x = new ByteString(buffer, HEX)
    pubKeyHash = x.bytes(0, x.length - 4).bytes(1) # remove network 1, remove checksum 4
    l pubKeyHash

    scriptPubKeyStart = Convert.toHexByte(bitcoin.opcodes.OP_DUP) + Convert.toHexByte(bitcoin.opcodes.OP_HASH160) + 14
    scriptPubKeyEnd = Convert.toHexByte(bitcoin.opcodes.OP_EQUALVERIFY) + Convert.toHexByte(bitcoin.opcodes.OP_CHECKSIG)
    scriptPubKey = bitcoin.Script.fromHex(scriptPubKeyStart + pubKeyHash.toString() + scriptPubKeyEnd)

    l change

    #txb.addOutput(scriptPubKey, @amount.toNumber()) # recipient addr
    txb.addOutput(scriptPubKey, @amount.toSatoshiNumber()) # recipient addr
    txb.addOutput(scriptPubKey, change) # change addr


    ###
    path = path.split('/')
    node = @_masterNode
    for item in path
      [index, hardened] = item.split "'"
      node  = if hardened? then node.deriveHardened parseInt(index) else node = node.derive index
    node = @_getNodeFromPath(associatedKeysets)
    ###

    for input, index in tx.ins
      l tx
      txb.sign(index, tx.ins[index].script.toHex())



    if not @amount? or not @fees? or not @recipientAddress?
      Errors.throw('Transaction must me initialized before preparation')
    d = ledger.defer(callback)
    @dongle.createPaymentTransaction(@_btInputs, @_btcAssociatedKeyPath, @changePath, @recipientAddress, @amount, @fees)
    .then (@_resumeData) =>
      @_validationMode = @_resumeData.authorizationRequired
      @authorizationPaired = @_resumeData.authorizationPaired
      d.resolve(@)
    .fail (error) =>
      d.rejectWithError(Errors.SignatureError)
    .done()
    d.promise

  # @param [String] validationKey 4 chars ASCII encoded
  # @param [Function] callback
  # @return [Q.Promise]
  validateWithPinCode: (validationPinCode, callback=undefined) -> @_validate((char.charCodeAt(0).toString(16) for char in validationPinCode).join(''), callback)

  # @param [String] validationKey 4 chars ASCII encoded
  # @param [Function] callback
  # @return [Q.Promise]
  validateWithKeycard: (validationKey, callback=undefined) -> @_validate(("0#{char}" for char in validationKey).join(''), callback)

  # @param [String] validationKey 4 bytes hex encoded
  # @param [Function] callback
  # @return [Q.Promise]
  _validate: (validationKey, callback=undefined) ->
    if not @_resumeData? or not @_validationMode?
      Errors.throw('Transaction must me prepared before validation')
    d = ledger.defer(callback)
    @dongle.createPaymentTransaction(
      @_btInputs, @_btcAssociatedKeyPath, @changePath, @recipientAddress, @amount, @fees,
      undefined, # Default lockTime
      undefined, # Default sigHash
      validationKey,
      @_resumeData
    ).then( (@_signedRawTransaction) =>
      @_isValidated = yes
      _.defer => d.resolve(@)
    ).catch( (error) =>
      _.defer => d.rejectWithError(Errors.SignatureError, error)
    ).done()
    d.promise

  ###
  Creates a new transaction asynchronously. The created transaction will only be initialized (i.e. it will only retrieve
  a sufficient number of input to perform the transaction)

  @param {ledger.Amount} amount The amount to send (expressed in satoshi)
  @param {ledger.Amount} fees The miner fees (expressed in satoshi)
  @param {String} address The recipient address
  @param {Array<String>} inputsPath The paths of the addresses to use in order to perform the transaction
  @param {String} changePath The path to use for the change
  @option [Function] callback The callback called once the transaction is created
  @return [Q.Promise] A closure
  ###
  @create: ({amount, fees, address, inputsPath, changePath}, callback = null) ->
    d = ledger.defer(callback)
    return d.rejectWithError(Errors.DustTransaction) && d.promise if amount.lte(Transaction.MINIMUM_OUTPUT_VALUE)
    return d.rejectWithError(Errors.NotEnoughFunds) && d.promise unless inputsPath?.length
    requiredAmount = amount.add(fees)

    ledger.api.UnspentOutputsRestClient.instance.getUnspentOutputsFromPaths inputsPath, (outputs, error) ->
      return d.rejectWithError(Errors.NetworkError, error) if error?
      # Collect each valid outputs and sort them by desired priority
      validOutputs = _(output for output in outputs when output.paths.length > 0).sortBy (output) ->  -output['confirmatons']
      return d.rejectWithError(Errors.NotEnoughFunds) if validOutputs.length == 0
      finalOutputs = []
      collectedAmount = new Amount()
      hadNetworkFailure = no

      # For each valid outputs we try to get its raw transaction.
      _.async.each validOutputs, (output, done, hasNext) =>
        ledger.api.TransactionsRestClient.instance.getRawTransaction output.transaction_hash, (rawTransaction, error) ->
          if error?
            hadNetworkFailure = yes
          else
            output.raw = rawTransaction
            finalOutputs.push(output)
            collectedAmount = collectedAmount.add(Amount.fromSatoshi(output.value))

          if collectedAmount.gte(requiredAmount)
            changeAmount = collectedAmount.subtract(requiredAmount)
            fees = fees.add(changeAmount) if changeAmount.lte(Transaction.MINIMUM_OUTPUT_VALUE)
            # We have reached our required amount. It's time to prepare the transaction
            transaction = new Transaction(ledger.app.dongle, amount, fees, address, finalOutputs, changePath)
            d.resolve(transaction)
          else if hasNext is true
            # Continue to collect funds
            done()
          else if hadNetworkFailure
            d.rejectWithError(Errors.NetworkError)
          else
            output.raw = rawTransaction
            finalOutputs.push(output)
            collectedAmount = collectedAmount.add(Amount.fromSatoshi(output.value))

          if collectedAmount.gte(requiredAmount)
            changeAmount = collectedAmount.subtract(requiredAmount)
            fees = fees.add(changeAmount) if changeAmount.lte(Transaction.MINIMUM_OUTPUT_VALUE)
            # We have reached our required amount. It's time to prepare the transaction
            transaction = new Transaction(ledger.app.dongle, amount, fees, address, finalOutputs, changePath)
            d.resolve(transaction)
          else if hasNext is true
            # Continue to collect funds
            done()
          else if hadNetworkFailure
            d.rejectWithError(Errors.NetworkError)
          else
            d.rejectWithError(Errors.NotEnoughFunds)
    d.promise
