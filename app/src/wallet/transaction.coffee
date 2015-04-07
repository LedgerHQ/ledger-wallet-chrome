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
  @DEFAULT_FEES: Amount.fromBits(50)
  #
  @MINIMUM_CONFIRMATIONS: 1
  #
  @MINIMUM_OUTPUT_VALUE: Amount.fromSatoshi(5430)

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
  # @property [Object]
  _transaction: undefined

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
  getSignedTransaction: () -> @_transaction

  # @return [Integer]
  getValidationMode: () -> @_validationMode

  # @return [ledger.Amount]
  getAmount: () -> @amount

  # @return [String]
  getRecipientAddress: () -> @receiverAddress

  # @param [String] hash
  setHash: (hash) -> @hash = hash

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

  # @param [Array<Object>] inputs
  # @param [String] changePath
  # @param [Function] callback
  # @return [Q.Promise]
  prepare: (callback=undefined) ->
    if not @amount? or not @fees? or not @recipientAddress?
      Errors.throw('Transaction must me initialized before preparation')
    d = ledger.defer(callback)
    @dongle.createPaymentTransaction(@_btInputs, @_btcAssociatedKeyPath, @changePath, @recipientAddress, @amount, @fees)
    .then (@_resumeData) =>
      @_validationMode = @_resumeData.authorizationRequired
      @authorizationPaired = @_resumeData.authorizationPaired
      d.resolve()
    .fail (error) =>
      d.rejectWithError(Errors.SignatureError)
    .done()
    d.promise
  
  # @param [String] validationKey 4 chars ASCII encoded
  # @param [Function] callback
  # @return [Q.Promise]
  validateWithPinCode: (validationPinCode, callback=undefined) -> @_validate(validationPinCode, callback)

  # @param [String] validationKey 4 chars ASCII encoded
  # @param [Function] callback
  # @return [Q.Promise]
  validateWithKeycard: (validationKey, callback = null) -> @_validate(("0#{char}" for char in validationKey).join(''), callback)

  # @param [String] validationKey 4 chars ASCII encoded
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
      resumeData
    )
    .then (@_transaction) =>
      @_isValidated = yes
      _.defer => d.resolve()
    .fail (error) =>
      _.defer => d.rejectWithError(Errors.SignatureError, error)
    .done()
    d.promise

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
        indexes: @_resumeData.indexesKeyCard.match(/../g)
      validationCharacters: (@recipientAddress[index] for index in @_resumeData.indexesKeyCard.match(/../g))
      needsAmountValidation: false

    # ~> 1.4.13 need validation on amount
    if @dongle.getIntFirmwareVersion() < @dongle.Firmware.V1_4_13
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
            return done()

          output.raw = rawTransaction
          finalOutputs.push(output)
          collectedAmount = collectedAmount.add(Amount.fromSatoshi(output.value))

          if collectedAmount.gte(requiredAmount)
            changeAmount = collectedAmount.subtract(requiredAmount)
            fees = fees.add(changeAmount) if changeAmount.lte(5400)
            # We have reached our required amount. It's time to prepare the transaction
            transaction = new Transaction(ledger.app.dongle, amount, fees, recipientAddress, finalOutputs, changePath)
            d.resolve(transaction)
          else if hasNext is true
            # Continue to collect funds
            done()
          else if hadNetworkFailure
            d.rejectWithError(Errors.NetworkError)
          else
            d.rejectWithError(Errors.NotEnoughFunds)
    d.promise
