@ledger.wallet ?= {}

@ledger.wallet.transaction ?= {}

class ledger.wallet.transaction.Transaction

  @ValidationModes:
    PIN: 0x01
    KEYCARD: 0x02
    SECURE_SCREEN: 0x03

  init: (@amount, @fees, @recipientAddress, @inputs, @changePath) ->
    @amount = ledger.wallet.Value.from(amount)
    @fees = ledger.wallet.Value.from(fees)
    @_isValidated = no
    @_btInputs = []
    @_btcAssociatedKeyPath = []
    for input in inputs
      splitTransaction = ledger.app.wallet._lwCard.dongle.splitTransaction(new ByteString(input.raw, HEX))
      @_btInputs.push [splitTransaction, input.output_index]
      @_btcAssociatedKeyPath.push input.paths[0]

  prepare: (callback) ->
    throw new ledger.StandardError(ledger.errors.TransactionNotInitialized) if not @amount? or not @fees? or not @recipientAddress?
    completion = new CompletionClosure(callback)
    try
      ledger.app.wallet._lwCard.dongle.createPaymentTransaction_async(
        @_btInputs,
        @_btcAssociatedKeyPath,
        @changePath,
        new ByteString(@recipientAddress, ASCII),
        @amount.toByteString(),
        @fees.toByteString()
      )
      .then (result) =>
        @_out = result
        @_out.scriptData = @_out.scriptData.toString(HEX)
        @_out.trustedInputs = (trustedInput.toString(HEX) for trustedInput in @_out.trustedInputs)
        @_out.publicKeys = (publicKey.toString(HEX) for publicKey in @_out.publicKeys)
        @_out.authorizationPaired = @_out.authorizationPaired.toString(HEX) if @_out.authorizationPaired?
        @_out.authorizationReference = @_out.authorizationReference.toString(HEX) if @_out.authorizationReference?
        @_validationMode = result.authorizationRequired
        completion.success(this)
      .fail (error) =>
        e error
        completion.failure(new ledger.StandardError(ledger.errors.SignatureError))
    catch error
      e error
      completion.failure(new ledger.StandardError(ledger.errors.UnknownError))
    completion.readonly()

  validateWithPinCode: (validationPinCode, callback = null) -> @_validate(new ByteString(validationPinCode, ASCII), callback)

  validateWithKeycard: (validationKey, callback = null) -> @_validate(new ByteString(("0#{char}" for char in validationKey).join(''), HEX), callback)

  _validate: (validationKey, callback = null) ->
    throw 'Transaction must me prepared before validation' if not @_out? or not @_validationMode?
    completion = new CompletionClosure(callback)
    out = _.clone(@_out)

    out.scriptData = new ByteString @_out.scriptData, HEX
    out.trustedInputs = (new ByteString(trustedInput, HEX) for trustedInput in @_out.trustedInputs)
    out.publicKeys = (new ByteString(publicKey, HEX) for publicKey in @_out.publicKeys)
    try
      ledger.app.wallet._lwCard.dongle.createPaymentTransaction_async(
        @_btInputs,
        @_btcAssociatedKeyPath,
        @changePath,
        new ByteString(@recipientAddress, ASCII),
        @amount.toByteString(),
        @fees.toByteString(),
        undefined, # Default lockTime
        undefined, # Default sigHash
        validationKey,
        out
      )
        .then (rawTransaction) =>
          @_isValidated = yes
          @_transaction = rawTransaction
          completion.success(this)
        .fail (error) ->
          completion.failWithStandardError(ledger.errors.SignatureError)
    catch error
      completion.failWithStandardError(ledger.errors.UnknownError)
    completion.readonly()

  isValidated: () -> @_isValidated

  getSignedTransaction: () ->
    throw 'Transaction should be validated before retrieving signed transaction' unless @_transaction?
    l "Push ", @_transaction.toString(HEX)
    @_transaction.toString(HEX)

  getValidationMode: () -> @_validationMode

  getAmount: () -> @amount

  getRecipientAddress: () -> @receiverAddress

  serialize: ->
    amount: @amount.toNumber(),
    address: @receiverAddress,
    fee: @fees.toNumber(),
    hash: @hash,
    raw: @getSignedTransaction()

  getValidationDetails: () ->
    indexes = []
    if @_validationMode is ledger.wallet.transaction.Transaction.ValidationModes.SECURE_SCREEN
      numberOfCharacters = parseInt(@_out.indexesKeyCard.substring(0, 2), 16)
      indexesKeyCard = @_out.indexesKeyCard.substring(2, numberOfCharacters * 2 + 2)
    else
      indexesKeyCard = @_out.indexesKeyCard
    amount = ''
    if ledger.app.wallet.getIntFirmwareVersion() < ledger.wallet.Firmware.V1_4_13
      stringifiedAmount = @amount.toString()
      stringifiedAmount = _.str.lpad(stringifiedAmount, 9, '0')
      decimalPart = stringifiedAmount.substr(stringifiedAmount.length - 8)
      integerPart = stringifiedAmount.substr(0, stringifiedAmount.length - 8)
      firstAmountValidationIndex = integerPart.length - 1
      lastAmountValidationIndex = firstAmountValidationIndex
      if decimalPart isnt "00000000"
        lastAmountValidationIndex += 3

    while indexesKeyCard.length >= 2
      index = indexesKeyCard.substring(0, 2)
      indexesKeyCard = indexesKeyCard.substring(2)
      indexes.push parseInt(index, 16)

    details =
      validationMode: @_validationMode
      amount:
        text: stringifiedAmount
        indexes: [firstAmountValidationIndex..lastAmountValidationIndex]
      recipientsAddress:
        text: @recipientAddress
        indexes: indexes
      validationCharacters: @getKeycardValidationCharacters()

    details.needsAmountValidation = details.amount.indexes.length > 0
    details

  getKeycardValidationCharacters: () ->
    indexes = []
    keycardIndexes = []

    if ledger.app.wallet.getIntFirmwareVersion() < ledger.wallet.Firmware.V1_4_13
      stringifiedAmount = @amount.toString()
      stringifiedAmount = _.str.lpad(stringifiedAmount, 9, '0')
      decimalPart = stringifiedAmount.substr(stringifiedAmount.length - 8)
      integerPart = stringifiedAmount.substr(0, stringifiedAmount.length - 8)
      keycardIndexes.push integerPart.charAt(integerPart.length - 1)
      if decimalPart isnt "00000000"
        keycardIndexes.push decimalPart.charAt(0)
        keycardIndexes.push decimalPart.charAt(1)
        keycardIndexes.push decimalPart.charAt(2)

    if @_validationMode is ledger.wallet.transaction.Transaction.ValidationModes.SECURE_SCREEN
      numberOfCharacters = parseInt(@_out.indexesKeyCard.substring(0, 2), 16)
      indexesKeyCard = @_out.indexesKeyCard.substring(2, numberOfCharacters * 2 + 2)
    else
      indexesKeyCard = @_out.indexesKeyCard
    while indexesKeyCard.length >= 2
      index = indexesKeyCard.substring(0, 2)
      indexesKeyCard = indexesKeyCard.substring(2)
      indexes.push parseInt(index, 16)
    keycardIndexes.push @recipientAddress[index] for index in indexes
    keycardIndexes

  setHash: (hash) -> @hash = hash

  ###
  Creates a new transaction asynchronously. The created transaction will only be initialized (i.e. it will only retrieve
  a sufficient number of input to perform the transaction)

  @param {ledger.wallet.Value} amount The amount to send expressed in satoshi
  @param {ledger.wallet.Value} fees The miner fees expressed in satoshi
  @param {String} address The recipient address
  @param {Array<String>} inputsPath The paths of the addresses to use in order to perform the transaction
  @param {String} changePath The path to use for the change
  @option [Function] callback The callback called once the transaction is created
  @return [CompletionClosure] A closure
  ###
  @create: ({amount, fees, address, inputsPath, changePath}, callback = null) ->
    completion = new CompletionClosure(callback)
    amount = ledger.wallet.Value.from(amount)
    fees = ledger.wallet.Value.from(fees)
    if amount.lte(ledger.wallet.transaction.MINIMUM_OUTPUT_VALUE)
      completion.failure(new ledger.StandardError(ledger.errors.DustTransaction))
      return completion.readonly()
    unless inputsPath?.length
      completion.failure(new ledger.StandardError(ledger.errors.NotEnoughFunds))
      return completion.readonly()
    ledger.api.UnspentOutputsRestClient.instance.getUnspentOutputsFromPaths inputsPath, (outputs, error) ->
      return completion.failure(error) if error?
      # Collect each valid outputs and sort them by desired priority
      validOutputs = _(output for output in outputs when output.paths.length > 0).sortBy (output) ->  -output['confirmatons']

      return completion.failure(new ledger.StandardError(ledger.errors.NotEnoughFunds)) if validOutputs.length == 0

      finalOutputs = []
      collectedAmount = new ledger.wallet.Value()
      requiredAmount = amount.add(fees)
      hadNetworkFailure = no
      # For each valid outputs we try to get its raw transaction.
      _.async.each validOutputs, (output, done, hasNext) ->
        ledger.api.TransactionsRestClient.instance.getRawTransaction output.transaction_hash, (rawTransaction, error) ->
          if error?
            hadNetworkFailure = yes
            completion.failure(new ledger.StandardError(ledger.errors.NetworkError)) unless hasNext
            return do done

          output.raw = rawTransaction
          finalOutputs.push output
          collectedAmount = collectedAmount.add output.value
          changeAmount = collectedAmount.subtract(amount).subtract(fees)
          if hasNext is true and collectedAmount.lt(requiredAmount) and changeAmount.lte(5400)
            # We have enough funds but if we send this, we will make a dust transaction so continue to collect
            do done
          else if hasNext is false and collectedAmount.lt(requiredAmount) and changeAmount.lte(5400) and changeAmount.gt(-1)
            # We have enough funds but if we send this, we will make a dust transaction so add the dust in miner fees
            fees = fees.add(changeAmount)
            transaction = new ledger.wallet.transaction.Transaction()
            transaction.init(amount, fees, address, finalOutputs, changePath)
            completion.success(transaction)
          else if hasNext is false and collectedAmount.lt(requiredAmount) and hadNetworkFailure
            # Not enough funds but error is probably caused by a previous network issue
            completion.failure(new ledger.StandardError(ledger.errors.NetworkError))
          else if hasNext is false and collectedAmount.lt(requiredAmount)
            # Not enough available funds
            completion.failure(new ledger.StandardError(ledger.errors.NotEnoughFunds))
          else if collectedAmount.gte requiredAmount
            # We have reached our required amount. It's time to prepare the transaction
            transaction = new ledger.wallet.transaction.Transaction()
            transaction.init(amount, fees, address, finalOutputs, changePath)
            completion.success(transaction)
          else
            # Continue to collect funds
            do done
    completion.readonly()

  _logger: -> ledger.utils.Logger.getLoggerByTag("Transaction")

_.extend ledger.wallet.transaction,

    MINIMUM_OUTPUT_VALUE: 5430


