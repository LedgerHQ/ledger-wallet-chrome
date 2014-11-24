class @Account extends Model
  do @init

  @hasMany operations: 'Operation'

  @fromHDWalletAccount: (hdAccount) ->
    return null unless hdAccount?
    @find(hdAccount.index)

  createTransaction: (amount, fees, recipientAddress, callback) ->
    transaction = new ledger.wallet.Transaction()
    transaction.init amount, fees, recipientAddress

  ## Balance management

  retrieveBalance: () ->
    ledger.tasks.BalanceTask.get(@getId()).startIfNeccessary()

  ## Operations

  addRawTransaction: (rawTransaction, callback) ->
    @exists (exists) =>
      return unless exists
      @get (account) =>
        hdAccount = ledger.wallet.HDWallet.instance?.getAccount(@getId())
        return unless hdAccount?

        @getOperations (operations) =>
          @_addRawTransaction account, operations, hdAccount.getAllPublicAddressesPaths(), rawTransaction, 'reception', (publicAdded) =>
            @_addRawTransaction account, operations, hdAccount.getAllChangeAddressesPaths(), rawTransaction, 'sending', (changeAdded) =>
              callback?(publicAdded or changeAdded)

  _addRawTransaction: (account, operations, paths, rawTransaction, type, done) ->
    ledger.wallet.pathsToAddresses paths, (addresses) =>
      value = 0

      foreignOutputs = []
      ownOutputs = []

      for output in rawTransaction.outputs
        continue unless output.addresses?
        for address in output.addresses
          if _(addresses).contains(address)
            ownOutputs.push output
          else
            foreignOutputs.push output
          break

      foreignInputs = []
      ownInputs = []

      for input in rawTransaction.inputs
        continue unless input.addresses?
        for address in input.addresses
          if _(addresses).contains(address)
            ownInputs.push output
          else
            foreignInputs.push output
          break

      return done(no) if ownOutputs.length == 0 and ownInputs.length == 0

      outputsToCompute = if type is 'reception' then ownOutputs else foreignOutputs

      value = 0

      if rawTransaction.outputs.length == 1
        value = rawTransaction.outputs[0].value
      else
        value = do (outputsToCompute) ->
          out = 0
          for output in outputsToCompute
            out += output.value
          out

      senders = []
      recipients = []

      for input in rawTransaction.inputs
        senders = senders.concat((address for address in input.addresses))

      outputsToCompute = if type is 'reception' then ownOutputs else foreignOutputs
      recipients = do (outputsToCompute) ->
          recipients = []
          for output in outputsToCompute
            recipients = recipients.concat((address for address in output.addresses))
          recipients

      transaction =
        _id: type + rawTransaction['hash']
        hash: rawTransaction['hash']
        fees: rawTransaction['fees']
        time: rawTransaction['chain_received_at']
        type: type
        value: value
        senders: JSON.stringify(senders)
        recipients: JSON.stringify(recipients)
        confirmations: rawTransaction['confirmations']
      @insertOperation transaction, => done(yes)

  insertOperation: (operation, callback) ->
    @exists (exists) =>
      return unless exists
      @get =>
        @getOperations (operations) =>
          operations.insert operation, callback

  getAllSortedOperations: (callback) ->
    @exists (exists) =>
      return callback([]) unless exists
      @getOperations (operations) =>
        operations.toArray (operations) =>
          out = _(operations).sortBy (operation) -> -(new Date(operation.time).getTime())
          callback?(out)