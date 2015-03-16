ValidationModes =
    PIN: 0x01
    KEYCARD: 0x02
    SECURE_SCREEN: 0x03

Errors = @ledger.errors

Value = ledger.wallet.Value

@ledger.dongle ?= {}

###
@example Usage
  ledger.dongle.Transaction.createAndPrepareTransaction(amount, fees, recipientAddress, inputsAccounts, changeAccount).then (tx) =>
    console.log("Prepared tx :", tx)
###
class ledger.dongle.Transaction
  #
  @ValidationModes: ValidationModes
  #
  @DEFAULT_FEES: Value.from(0.00005)
  #
  @MINIMUM_CONFIRMATIONS: 1

  # @property [Value]
  amount: undefined
  # @property [Value]
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


  # @param [String, Number, Value] amount
  # @param [String, Number, Value] fees
  # @param [String] recipientAddress
  # @return [CompletionClosure]
  init: (amount, fees, @recipientAddress) ->
    @amount = Value.from(amount)
    @fees = Value.from(fees)

  # @return [Boolean]
  isValidated: () -> @_isValidated

  # @return [String]
  getSignedTransaction: () -> @_transaction

  # @return [Integer]
  getValidationMode: () -> @_validationMode

  # @return [Value]
  getAmout: () -> @amount

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
        splitTransaction = ledger.app.wallet._lwCard.dongle.splitTransaction(input)
        @_btInputs.push [splitTransaction, input.output_index]
        @_btcAssociatedKeyPath.push input.paths[0]
    catch err
      completion.failure(new ledger.StandardError(Errors.UnknowError, err))

    ledger.app.dongle.createPaymentTransaction(@_btInputs, @_btcAssociatedKeyPath, @changePath, @recipientAddress, @amount, @fees)
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
    ledger.app.dongle.createPaymentTransaction(
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

  getValidationDetails: () ->
    indexes = []
    indexesKeyCard = @_resumeData.indexesKeyCard
    amount = ''
    if ledger.app.dongle.getIntFirmwareVersion() < ledger.dongle.Firmware.V1_4_13
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

    indexesKeyCard = @_resumeData.indexesKeyCard
    while indexesKeyCard.length >= 2
      index = indexesKeyCard.substring(0, 2)
      indexesKeyCard = indexesKeyCard.substring(2)
      indexes.push parseInt(index, 16)

    keycardIndexes.push(@recipientAddress[index]) for index in indexes
    keycardIndexes

  # @param [Integer] amount
  # @param [Integer] fees
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
    amount = ledger.wallet.Value.from(amount)
    fees = ledger.wallet.Value.from(fees)
    requiredAmount = amount.add(fees)
    l "Required amount", requiredAmount.toString()

    transaction = new ledger.dongle.Transaction()
    transaction.init(amount, fees, recipientAddress)
    ledger.api.UnspentOutputsRestClient.instance.getUnspentOutputsFromPaths inputsPath, (outputs, error) ->
      return completion.error(Errors.NetworkError, error) if error?
      
      # Collect each valid outputs and sort them by desired priority
      validOutputs = _.chain(validOutputs)
        .filter((output) -> output.paths.length > 0)
        .sortBy((output) -> -output['confirmations'])
        .value()
      l "Valid outputs :", validOutputs
      return completion.error(Errors.NotEnoughFunds) if validOutputs.length == 0
      
      # For each valid outputs we try to get its raw transaction.
      finalOutputs = []
      collectedAmount = new ledger.wallet.Value()
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
