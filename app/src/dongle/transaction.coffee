ValidationModes =
    PIN: 0x01
    KEYCARD: 0x02
    SECURE_SCREEN: 0x03

Errors = @ledger.errors

Amount = ledger.Amount

@ledger.dongle ?= {}

###
@example Usage
  amount = ledger.Amount.fromBtc("1.234")
  fee = ledger.Amount.fromBtc("0.0001")
  recipientAddress = "1DR6p2UVfu1m6mCU8hyvh5r6ix3dJEPMX7"
  ledger.dongle.Transaction.createAndPrepareTransaction(amount, fees, recipientAddress, inputsAccounts, changeAccount).then (tx) =>
    console.log("Prepared tx :", tx)
###
class ledger.dongle.Transaction
  #
  @ValidationModes: ValidationModes
  #
  @DEFAULT_FEES: Amount.fromBtc(0.00005)
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
  constructor: (@dongle, @amount, @fees, @recipientAddress) ->

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

  # @param [Array<Object>] inputs
  # @param [String] changePath
  # @param [Function] callback
  # @return [CompletionClosure]
  prepare: (@inputs, @changePath, callback=undefined) ->
    if not @amount? or not @fees? or not @recipientAddress?
      throw new ledger.StandardError('Transaction must me initialized before preparation')
    completion = new CompletionClosure(callback)
    try
      @_btInputs = []
      @_btcAssociatedKeyPath = []
      for input in inputs
        splitTransaction = @dongle.splitTransaction(input)
        @_btInputs.push [splitTransaction, input.output_index]
        @_btcAssociatedKeyPath.push input.paths[0]
    catch err
      completion.failure(new ledger.StandardError(Errors.UnknowError, err))

    @dongle.createPaymentTransaction(@_btInputs, @_btcAssociatedKeyPath, @changePath, @recipientAddress, @amount, @fees)
    .then (@_resumeData) =>
      @_validationMode = @_resumeData.authorizationRequired
      completion.success()
    .fail (error) =>
      completion.failure(new ledger.StandardError(Errors.SignatureError))
    .done()

    completion.readonly()
  
  # @param [String] validationKey 4 chars ASCII encoded
  # @param [Function] callback
  # @return [CompletionClosure]
  validate: (validationKey, callback=undefined) ->
    if not @_resumeData? or not @_validationMode?
      throw new ledger.StandardError('Transaction must me prepared before validation')
    completion = new CompletionClosure(callback)
    # Convert ASCII encoded validationKey to HEX encoded validationKey
    if @_validationMode == ValidationModes.KEYCARD
      validationKey = ("0#{char}" for char in validationKey.split('')).join('') 
    else
      validationKey = (validationKey.charCodeAt(i).toString(16) for i in [0...validationKey.length]).join('')
    @dongle.createPaymentTransaction(
      @_btInputs, @_btcAssociatedKeyPath, @changePath, @recipientAddress, @amount, @fees,
      undefined, # Default lockTime
      undefined, # Default sigHash
      validationKey,
      resumeData
    )
    .then (@_transaction) =>
      @_isValidated = yes
      _.defer => completion.success()
    .fail (error) =>
      _.defer => completion.failure(new ledger.StandardError(Errors.SignatureError, error))
    .done()
    completion.readonly()

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

  # @param [ledger.Amount] amount
  # @param [ledger.Amount] fees
  # @param [String] recipientAddress
  # @param [Array] inputsAccounts
  # @param [?] changeAccount
  # @param [Function] callback
  # @return [CompletionClosure]
  @createAndPrepareTransaction: (amount, fees, recipientAddress, inputsAccounts, changeAccount, callback=undefined) ->
    completion = new CompletionClosure(callback)
    inputsAccounts = [inputsAccounts] unless _.isArray inputsAccounts
    inputsPaths = _.flatten(inputsAccount.getHDWalletAccount().getAllAddressesPaths() for inputsAccount in inputsAccounts)
    changePath = changeAccount.getHDWalletAccount().getCurrentChangeAddressPath()
    requiredAmount = amount.add(fees)
    l "Required amount", requiredAmount.toString()

    transaction = new ledger.dongle.Transaction(ledger.app.dongle, amount, fees, recipientAddress)
    ledger.api.UnspentOutputsRestClient.instance.getUnspentOutputsFromPaths inputsPath, (outputs, error) ->
      return completion.error(Errors.NetworkError, error) if error?
      
      # Collect each valid outputs and sort them by desired priority
      validOutputs = _.chain(outputs)
        .filter((output) -> output.paths.length > 0)
        .sortBy((output) -> -output['confirmations'])
        .value()
      l "Valid outputs :", validOutputs
      return completion.error(Errors.NotEnoughFunds) if validOutputs.length == 0
      
      # For each valid outputs we try to get its raw transaction.
      finalOutputs = []
      collectedAmount = new Amount()
      hadNetworkFailure = no
      _.async.each validOutputs, (output, done, hasNext) =>
        ledger.api.TransactionsRestClient.instance.getRawTransaction output.transaction_hash, (rawTransaction, error) ->
          if error?
            hadNetworkFailure = yes
            return done()

          output.raw = rawTransaction
          finalOutputs.push(output)
          collectedAmount = collectedAmount.add(output.value)
          l "Required amount :", requiredAmount.toString(), ", Collected amount :", collectedAmount.toString(), "has next ?", hasNext

          if collectedAmount.gte(requiredAmount)
            # We have reached our required amount. It's time to prepare the transaction
            transaction.prepare(finalOutputs, changePath)
            .then => completion.success(transaction)
            .fail (error) => completion.failure(error)
          else if hasNext is true
            # Continue to collect funds
            done()
          else if hadNetworkFailure
            completion.error(Errors.NetworkError)
          else
            completion.error(Errors.NotEnoughFunds)

    completion.readonly()
