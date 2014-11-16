@ledger.wallet ?= {}

@ledger.wallet.transaction ?= {}

class ledger.wallet.transaction.Transaction

  @ValidationModes:
    PIN: 0x01
    KEYCARD: 0x02

  init: (@amount, @fees, @recipientAddress) ->
    @amount = ledger.wallet.Value.from(amount)
    @fees = ledger.wallet.Value.from(fees)

  prepare: (@inputs, @changePath, callback) ->
    throw 'Transaction must me initialized before preparation' if not @amount? or not @fees? or not @recipientAddress?
    try
      @_btInputs = []
      @_btcAssociatedKeyPath = []
      for input in inputs
        splitTransaction = ledger.app.wallet._lwCard.dongle.splitTransaction(new ByteString(input.raw, HEX))
        @_btInputs.push [splitTransaction, input.output_index]
        @_btcAssociatedKeyPath.push input.paths[0]
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
        @_validationMode = result.authorizationRequired
        callback?(@)
      .fail (error) =>
        callback?(null, {title: 'Signature Error', code: ledger.errors.SignatureError})
    catch error
      callback?(null, {title: 'An error occured', code: ledger.errors.UnknownError})

  validate: (validationKey, callback) ->
    throw 'Transaction must me prepared before validation' if not @_out? or not @_validationMode?

    validationKey = ("0#{char}" for char in validationKey).join('')
    l validationKey
    @_out.scriptData = new ByteString @_out.scriptData, HEX
    @_out.trustedInputs = (new ByteString(trustedInput, HEX) for trustedInput in @_out.trustedInputs)
    @_out.publicKeys = (new ByteString(publicKey, HEX) for publicKey in @_out.publicKeys)

    validationKey = switch @_validationMode
      when ledger.wallet.transaction.Transaction.ValidationModes.KEYCARD then new ByteString(validationKey, HEX)
      when ledger.wallet.transaction.Transaction.ValidationModes.PIN then new ByteString(validationKey, ASCII)
    l validationKey
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
        @_out
      )
        .then (rawTransaction) =>
          @_transaction = rawTransaction
          callback?(this)
        .fail (error) ->
          callback?(null, {title: 'Signature Error', code: ledger.errors.SignatureError, error})
    catch error
      callback?(null, {title: 'Unknown Error', code: ledger.errors.UnknownError, error})

  getSignedTransaction: () ->
    throw 'Transaction should be validated before retrieving signed transaction' unless @_transaction?
    @_transaction.toString(HEX)

  getValidationMode: () -> @_validationMode

  getKeycardIndexes: () ->
    indexes = []
    indexesKeyCard = @_out.indexesKeyCard
    while indexesKeyCard.length >= 2
      index = indexesKeyCard.substring(0, 2)
      indexesKeyCard = indexesKeyCard.substring(2)
      indexes.push parseInt(index, 16)
    keycardIndexes = []
    keycardIndexes.push @recipientAddress[index] for index in indexes
    keycardIndexes

  setHash: (hash) -> @hash = hash


_.extend ledger.wallet.transaction,

    MINIMUM_CONFIRMATIONS: 2

    createAndPrepareTransaction: (amount, fees, recipientAddress, inputsPath, changePath, callback) ->
      amount = ledger.wallet.Value.from(amount)
      fees = ledger.wallet.Value.from(fees)
      transaction = new ledger.wallet.transaction.Transaction()
      transaction.init(amount, fees, recipientAddress)
      ledger.api.UnspentOutputsRestClient.instance.getUnspentOutputsFromPaths inputsPath, (outputs, error) ->
        return callback?(null, {title: 'Network Error', error, code: ledger.errors.NetworkError}) if error?

        validOutputs = []
        # Collect each valid outputs
        for output in outputs
          continue if output.confirmations < ledger.wallet.transaction.MINIMUM_CONFIRMATIONS or output.paths.length is 0
          output.priority = inputsPath.indexOf(output.paths[0])
          validOutputs.push output

        # Sort outputs by desired priority
        validOutputs = _(validOutputs).sortBy (output) -> output.priority

        finalOutputs = []
        collectedAmount = new ledger.wallet.Value()
        requiredAmount = amount.add(fees)
        hadNetworkFailure = no
        # For each valid outputs we try to get its raw transaction.
        _.async.each validOutputs, (output, done, hasNext) ->
          l output
          ledger.api.TransactionsRestClient.instance.getRawTransaction output.transaction_hash, (rawTransaction, error) ->
            if error?
              hadNetworkFailure = yes
              return do done

            output.raw = rawTransaction
            finalOutputs.push output
            collectedAmount = collectedAmount.add output.value
            if hasNext is false and collectedAmount.lt(requiredAmount) and hadNetworkFailure
              # Not enough funds but error is probably caused by a previous network issue
              callback?(null, {title: 'Network Error', code: ledger.errors.NetworkError})
            else if hasNext is false and collectedAmount.lt(requiredAmount)
              # Not enough available funds
              callback?(null, {title: 'Not enough founds', code: ledger.errors.NotEnoughFunds})
            else if collectedAmount.gte requiredAmount
              # We have reached our required amount. It's to prepare the transaction
              _.defer -> transaction.prepare(outputs, changePath, callback)
            else
              # Continue to collect funds
              do done

