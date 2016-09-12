ValidationModes =
    PIN: 0x01
    KEYCARD: 0x02
    SECURE_SCREEN: 0x03
    KEYCARD_NEW: 0x04

Errors = @ledger.errors

Amount = ledger.Amount

$log = -> ledger.utils.Logger.getLoggerByTag("Transaction")
$info = (args...) -> $log().info args...
$error = (args...) -> $log().error args...

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

  @ValidationModes: ValidationModes
  @MINIMUM_OUTPUT_VALUE: Amount.fromSatoshi(5430)

  # @property [ledger.Amount]
  amount: undefined
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
    if @dongle.getIntFirmwareVersion() < ledger.dongle.Firmwares.V_B_1_4_13
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
      details.amount =
        text: stringifiedAmount
        indexes: [firstIdx..lastIdx]
      details.needsAmountValidation = true

    return details

  # @param [Array<Object>] inputs
  # @param [String] changePath
  # @param [Function] callback
  # @return [Q.Promise]
  prepare: (callback = undefined, progressCallback = undefined) ->
    if not @amount? or not @fees? or not @recipientAddress?
      Errors.throw('Transaction must me initialized before preparation')
    d = ledger.defer(callback)
    l "Prepare", @_btInputs, @_btcAssociatedKeyPath
    @dongle.createPaymentTransaction(@_btInputs, @_btcAssociatedKeyPath, @changePath, @recipientAddress, @amount, @fees)
    .progress (progress) =>
      currentStep = progress.currentPublicKey + progress.currentSignTransaction + progress.currentTrustedInput + progress.currentHashOutputBase58 + progress.currentUntrustedHash
      stepsCount = progress.publicKeyCount + progress.transactionSignCount + progress.trustedInputsCount + progress.hashOutputBase58Count + progress.untrustedHashCount
      for key, value of progress
        [__, index] = key.match(/currentTrustedInputProgress_(\d)/) or [null, null]
        continue unless index?
        currentStep += progress["currentTrustedInputProgress_#{index}"]
        stepsCount += progress["trustedInputsProgressTotal_#{index}"]
      percent = Math.ceil(currentStep / stepsCount * 100)
      d.notify({currentStep, stepsCount, percent})
      progressCallback?({currentStep, stepsCount, percent})
    .then (@_resumeData) =>
      @_validationMode = @_resumeData.authorizationRequired
      @authorizationPaired = @_resumeData.authorizationPaired
      @encryptedOutputScript = @_resumeData.encryptedOutputScript
      d.resolve(@)
    .fail (error) =>
      e "GOT ERROR", error
      d.rejectWithError(Errors.SignatureError)
    .done()
    d.promise

  sign: (callback = undefined, progressCallback = undefined) ->
    d = ledger.defer(callback)
    l "Prepare", @_btInputs, @_btcAssociatedKeyPath
    @dongle.createPaymentTransaction(@_btInputs, @_btcAssociatedKeyPath, @changePath, @recipientAddress, @amount, @fees)
    .progress (progress) =>
      d.notify(progress)
    .then (@_signedRawTransaction) =>
      @_isValidated = yes
      tx = ledger.bitcoin.decodeTransaction(@getSignedTransaction())
      $info("Raw TX: ", @getSignedTransaction())
      ledger.wallet.pathsToAddresses [@changePath], (addresses) =>
        changeAddress = _(addresses).chain().values().first().value()
        result = ledger.bitcoin.verifyRawTx(@getSignedTransaction(), @inputs, @amount, @fees, @recipientAddress, changeAddress)
        if result.isSuccess()
          _.defer => d.resolve(@)
        else
          $error("Invalid signed tx ", result.getError().message)
          return d.rejectWithError(Errors.ChangeDerivationError)
    .fail (error) =>
      e "GOT ERROR", error
      d.rejectWithError(Errors.SignatureError)
    .done()
    d.promise


  # @param [String] validationKey 4 chars ASCII encoded
  # @param [Function] callback
  # @return [Q.Promise]
  validateWithPinCode: (validationPinCode, callback=undefined, progressCallback=undefined) -> @_validate((char.charCodeAt(0).toString(16) for char in validationPinCode).join(''), callback, progressCallback)

  # @param [String] validationKey 4 chars ASCII encoded
  # @param [Function] callback
  # @return [Q.Promise]
  validateWithKeycard: (validationKey, callback=undefined, progressCallback=undefined) -> @_validate(("0#{char}" for char in validationKey).join(''), callback, progressCallback)

  # @param [String] validationKey 4 bytes hex encoded
  # @param [Function] callback
  # @return [Q.Promise]
  _validate: (validationKey, callback=undefined, progressCallback=undefined) ->
    if not @_resumeData? or not @_validationMode?
      Errors.throw('Transaction must me prepared before validation')
    d = ledger.defer(callback)
    @dongle.createPaymentTransaction(
      @_btInputs, @_btcAssociatedKeyPath, @changePath, @recipientAddress, @amount, @fees,
      undefined, # Default lockTime
      undefined, # Default sigHash
      validationKey,
      @_resumeData
    ).progress (progress) =>
      currentStep = progress.currentPublicKey + progress.currentSignTransaction + progress.currentTrustedInput + progress.currentHashOutputBase58 + progress.currentUntrustedHash
      stepsCount = progress.publicKeyCount + progress.transactionSignCount + progress.trustedInputsCount + progress.hashOutputBase58Count + progress.untrustedHashCount
      for key, value of progress
        [__, index] = key.match(/currentTrustedInputProgress_(\d)/) or [null, null]
        continue unless index
        currentStep += progress["currentTrustedInputProgress_#{index}"]
        stepsCount += progress["trustedInputsProgressTotal_#{index}"]
      percent = Math.ceil(currentStep / stepsCount * 100)
      d.notify({currentStep, stepsCount, percent})
      progressCallback?({currentStep, stepsCount, percent})
    .then (@_signedRawTransaction) =>
      @_isValidated = yes
      tx = ledger.bitcoin.decodeTransaction(@getSignedTransaction())
      $info("Raw TX: ", @getSignedTransaction())
      ledger.wallet.pathsToAddresses [@changePath], (addresses) =>
        changeAddress = _(addresses).chain().values().first().value()
        result = ledger.bitcoin.verifyRawTx(@getSignedTransaction(), @inputs, @amount, @fees, @recipientAddress, changeAddress)
        if result.isSuccess()
          _.defer => d.resolve(@)
        else
          $error("Invalid signed tx ", result.getError().message)
          return d.rejectWithError(Errors.ChangeDerivationError)
    .catch (error) =>
      _.defer => d.rejectWithError(Errors.SignatureError, error)
    .done()
    d.promise

  ###
    Creates a new transaction asynchronously. The created transaction will only be initialized (i.e. it will only retrieve
    a sufficient number of input to perform the transaction)

    @param {ledger.Amount} amount The amount to send (expressed in satoshi)
    @param {ledger.Amount} fees The miner fees (expressed in satoshi)
    @param {String} address The recipient address
    @param {Array<Output>} utxo The list of utxo to sign in order to perform the transaction
    @param {String} changePath The path to use for the change
    @option [Function] callback The callback called once the transaction is created
    @return [Q.Promise] A closure
  ###
  @create: ({amount, fees, address, utxo, changePath}, callback = null) ->
    d = ledger.defer(callback)
    dust = Amount.fromSatoshi(ledger.config.network.dust)
    l "CREATE TRANSACTION", arguments
    l "DUST", dust
    return d.rejectWithError(Errors.DustTransaction) && d.promise if amount.lte(dust)
    totalUtxoAmount = _(utxo).chain().map((u) -> ledger.Amount.fromSatoshi(u.get('value'))).reduce(((a, b) -> a.add(b)), ledger.Amount.fromSatoshi(0)).value()
    return d.rejectWithError(Errors.NotEnoughFunds) && d.promise if totalUtxoAmount.lt(amount.add(fees))
    # Check if UTXO are safe to spend
    
    #return d.rejectWithError(Errors.No)
    $info("--- CREATE TRANSACTION ---")
    $info("Amount: ", amount.toString())
    $info("Fees: ", fees.toString())
    $info("Total send: ", totalUtxoAmount.toString())
    $info("Address: ", address)
    $info("UTXO: ", utxo)
    $info("Change path: ", changePath)

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
         return d.rejectWithError(Errors.NetworkError)
        result = raw: rawTransaction, paths: [output.get('path')], output_index: output.get('index'), value: output.get('value')
        d.resolve(iterate(index + 1, inputs.concat([result])))
      d.promise
    d.resolve(iterate(0, []).then (inputs) => new Transaction(ledger.app.dongle, amount, fees, address, inputs, changePath))
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
  ###
  @create: ({amount, fees, address, inputsPath, changePath, excludedInputs}, callback = null) ->
    d = ledger.defer(callback)
    return d.rejectWithError(Errors.DustTransaction) && d.promise if amount.lte(Transaction.MINIMUM_OUTPUT_VALUE)
    return d.rejectWithError(Errors.NotEnoughFunds) && d.promise unless inputsPath?.length
    requiredAmount = amount.add(fees)

    excludedInputs = excludedInputs or []

    $info("--- CREATE TRANSACTION ---")
    $info("Amount: ", amount.toString())
    $info("Fees: ", fees.toString())
    $info("Address: ", address)
    $info("Inputs paths: ", inputsPath)
    $info("Change path: ", changePath)
    $info("Excluded inputs", excludedInputs)


    isOutputExcluded = (output) ->
      return for [index, hash] in excludedInputs when output['transaction_hash'] is hash and output['output_index'] is index
      no

    ledger.app.dongle.getPublicAddress changePath, (dongleChangeAddress) ->
      ledger.tasks.AddressDerivationTask.instance.getPublicAddress changePath, (workerChangeaddress, error) ->
        if dongleChangeAddress.bitcoinAddress.toString(ASCII) isnt workerChangeaddress
          $error("Error change derivation error #{changePath} ", dongleChangeAddress.bitcoinAddress.toString(ASCII), " <> ", workerChangeaddress)
          return d.rejectWithError(Errors.ChangeDerivationError)
        ledger.api.UnspentOutputsRestClient.instance.getUnspentOutputsFromPaths inputsPath, (outputs, error) ->
          if error?
            $error("Error during unspents outputs gathering", error)
            return d.rejectWithError(Errors.NetworkError, error)
          # Collect each valid outputs and sort them by desired priority

          validOutputs =
            _(output for output in outputs when output.paths.length > 0 and !isOutputExcluded(output))
              .chain()
              .sortBy (output) ->  -output['confirmatons']
              .value()
          if validOutputs.length == 0
            $error("Error not enough funds")
            return d.rejectWithError(Errors.NotEnoughFunds)
          validOutputs = _(validOutputs).uniq no, (i) ->  i['output_index'] +  i['transaction_hash']
          finalOutputs = []
          collectedAmount = new Amount()
          collectedAmountWithUnconfirmed = new Amount()
          hadNetworkFailure = no
          $info("Valid outputs: ", validOutputs)

          # For each valid outputs we try to get its raw transaction.
          _.async.each validOutputs, (output, done, hasNext) =>
            ledger.api.TransactionsRestClient.instance.getRawTransaction output.transaction_hash, (rawTransaction, error) ->
              if error?
                hadNetworkFailure = yes
              else if output.confirmations is 0 and !output.paths[0].match(/\d+'\/\d+'\/\d+'\/1\/\d+/)?
                collectedAmountWithUnconfirmed = collectedAmountWithUnconfirmed.add(Amount.fromSatoshi(output.value))
              else
                output.raw = rawTransaction
                finalOutputs.push(output)
                collectedAmount = collectedAmount.add(Amount.fromSatoshi(output.value))
                collectedAmountWithUnconfirmed = collectedAmountWithUnconfirmed.add(Amount.fromSatoshi(output.value))
              if collectedAmount.gte(requiredAmount)
                changeAmount = collectedAmount.subtract(requiredAmount)
                fees = fees.add(changeAmount) if changeAmount.lte(Transaction.MINIMUM_OUTPUT_VALUE)

                $info("Used outputs: ", finalOutputs)

                # We have reached our required amount. It's time to prepare the transaction
                transaction = new Transaction(ledger.app.dongle, amount, fees, address, finalOutputs, changePath)
                d.resolve(transaction)
              else if hasNext is true
                # Continue to collect funds
                done()
              else if collectedAmountWithUnconfirmed.gte(requiredAmount)
                d.rejectWithError(Errors.NotEnoughFundsConfirmed)
              else if hadNetworkFailure
                d.rejectWithError(Errors.NetworkError)
              else
                d.rejectWithError(Errors.NotEnoughFunds)
    d.promise
  ###