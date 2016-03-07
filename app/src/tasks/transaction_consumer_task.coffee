###
  This class holds a stream of transaction and is responsible for inserting them in the database. All application modules
  must feed the stream and should not consider inserting/updating transactions data.

  The stream should only accept JSON formatted transactions

  @example Transaction format
     {
      "hash":"38ea5d67277ad65c8c2c1760898fb26f12d32e81109a5eeabee3c227219883a5",
      "block_hash":"00000000000000001428ee1c464628567ae9267e6b942a85897a35a95283aa5b",
      "block_time":"2015-07-09T14:59:02Z",
      "confirmations":990,
      "lock_time":0,
      "inputs":[
         {
            "output_hash":"9da5299f0fc92ba495f336dab06fd4ef41c2732ce92bceac03eacc61ceebd9cd",
            "output_index":1,
            "value":1000000,
            "addresses":[
               "1AKiuYKJfaMA6wS54oomYMabvfudLCimz2"
            ]
         },
         {
            "output_hash":"587fe083c4d88cedada9238dcfdeb4bb532ddbe550648fdf65a05264a9902437",
            "output_index":1,
            "value":141220757,
            "addresses":[
               "16ikkRZAYXnmUAYanoVYBkZkuCnrKfpCca"
            ]
         }
      ],
      "outputs":[
         {
            "output_index":0,
            "value":10000000,
            "addresses":[
               "1Kmz7KqZWM5RuSjjGNfjPxwNbHmyJMHRCY"
            ],
            "required_signatures":1,
         },
         {
            "output_index":1,
            "value":132175914,
            "addresses":[
               "1E6q1KkrCDDjA8CqRLB42mjwq59gSLA3HR"
            ],
            "required_signatures":1,
         }
      ],
      "fees":44843,
      "amount":142175914
   }

  @example Transaction format v2
  {
      "hash": "da21f9616fb92a7fbe5e72d1537fe30e9b33603d456af72747baf5e5d28f54e3",
      "received_at": "2015-07-06T15:48:58Z",
      "lock_time": 0,
      "block": {
        "hash": "0000000000000000053197f9e8e5b0601071be99ca2a5c6ba18252a1aa895b04",
        "height": 364133,
        "time": "2015-07-06T15:48:58Z"
      },
      "inputs": [
        {
          "output_hash": "a8e499e551c4729ae74bf2136d3e046601e68f09ae30ed187bd772fc375a772e",
          "output_index": 0,
          "input_index": 0,
          "value": 1000000,
          "addresses": [
            "1Jt4tMBHBgiGcVFEDZKAEjqvqWxSUZrJxR"
          ],
          "script_signature": "473044022064dd34233b584ef220049a012294e50c0d05b9b1131843fad89982fc055af6d102202d2d96055859857a96702ebb8167eec2aae3e3269309432943c7f92718efcd8601210387ec9eb50e00c73984917d12610919d945c16ef1f52454306a8757368c004e7b"
        },
        {
          "output_hash": "a8e499e551c4729ae74bf2136d3e046601e68f09ae30ed187bd772fc375a772e",
          "output_index": 1,
          "input_index": 1,
          "value": 148513500,
          "addresses": [
            "1L3TGaALb8tVLNjuxRcePfYFr2nS2wpWwQ"
          ],
          "script_signature": "47304402202a70262a9c9510b6bc37df3ab395a79cf6ea9def1a31ba403d91754d65bc6b5b02206d7dac112b116c9715e59c83e96eac60dee03f712b137f4d6e3ce495dd2bb94a012102c21b0b1cc945e855f7fd71518811faa85954edd370b36f9c29d86f8fe792baa7"
        }
      ],
      "outputs": [
        {
          "output_index": 0,
          "value": 1000000,
          "addresses": [
            "18VLgzpLjLMRB8udaSrs4ha8gwzjzVgHUT"
          ],
          "script_hex": "76a9145224f6a5cbfa97dbe098bd72c1813c60982ff04e88ac"
        },
        {
          "output_index": 1,
          "value": 148503500,
          "addresses": [
            "1BcmwbMrp6tXATwRUkRUdzgo3MyQSFMn4M"
          ],
          "script_hex": "76a914747554e1770e5a3cd05f03fdf3a3961290f599f688ac"
        }
      ],
      "fees": 10000,
      "amount": 149503500
    }

###
class ledger.tasks.TransactionConsumerTask extends ledger.tasks.Task

  @reset: -> @instance = new @

  constructor: ->
    super 'global_transaction_consumer'
    @_deferredWait = {}
    safe = (f) ->
      (err, i, push, next) ->
        if err?
          ledger.utils.Logger.getLoggerByTag("TransactionStream").error("An error occured", err)
          push(err)
          return do next
        return push(null, ledger.stream.nil) if i is ledger.stream.nil
        f(err, i, push, next)
    @_input = ledger.stream()
    @_stream = ledger.stream(@_input)
      .consume(safe(@_extendTransaction.bind(@)))
      .filter(@_filterTransaction.bind(@))
      .consume(safe(@_updateDatabase.bind(@)))

    @_errorInput = ledger.stream()
    @_errorStream = ledger.stream(@_errorInput)


  ###

  ###
  pushCallback: (callback) ->
    @_input.write(callback)
    @

  ###
    Push a single json formatted transaction into the stream.
  ###
  pushTransaction: (transaction) ->
    return @pushTransactions(transaction) if _.isArray(transaction)
    unless transaction?
      $warn "Transaction consumer received a null transaction.", new Error().stack
      return
    @_input.write(transaction)
    @

  pushTransactionsFromStream: (stream) ->
    stream.each (transaction) =>
      @pushTransaction(transaction)

  ###
    Push an array of json formatted transactions into the stream.
  ###
  pushTransactions: (transactions) ->
    @pushTransaction(transaction) for transaction in transactions
    @

  ###
    Get an observable version of the transaction stream
  ###
  observe: -> @_stream.fork()

  ###
    Return a promise completed once a transaction is inserted/updated in the database
  ###
  waitForTransactionToBeInserted: (txHash) -> (@_deferredWait[txHash] ||= ledger.defer()).promise

  ###
    Get an observable version of the error stream
  ###
  errorStream: -> @_errorStream.observe()

  onStart: ->
    super
    @_input.resume()
    @_stream.resume()

  onStop: ->
    super
    @_input.end()
    @_stream.pause()
    @_stream.end()

  _requestDerivations: ->
    d = ledger.defer()
    ledger.wallet.pathsToAddresses ledger.wallet.Wallet.instance.getAllObservedAddressesPaths(), (addresses) ->
      d.resolve(_.invert(addresses))
    d.promise

  _getAddressCache: -> @_requestDerivations()

  ###
    Extends the given transaction with derivation paths and related accounts
    @private
  ###
  _extendTransaction: (err, transaction, push, next) ->
    if _.isFunction(transaction)
      Try -> transaction()
      push null, transaction
      return next()
    wallet = ledger.wallet.Wallet.instance
    @_getAddressCache().then (cache) =>
      transaction.accounts = []
      extendIos = (ios) ->
        hasOwn = no
        for io in ios
          io.paths = []
          io.accounts = []
          io.nodes = []
          io.addresses ||= _.compact([io.address])
          for address in (io.addresses or [])
            path = cache[address]
            io.paths.push path
            if path?
              ledger.wallet.Wallet.instance.getAccountFromDerivationPath(path).notifyPathsAsUsed([path])
              hasOwn = yes
            io.accounts.push (if path? then wallet.getOrCreateAccountFromDerivationPath(path) else undefined)
            if path?
              if ios is transaction.outputs
                (transaction.ownOutputs ||= []).push io
              [__, accountIndex, node, index] = path.match("#{wallet.getRootDerivationPath()}/(\\d+)'/(0|1)/(\\d+)")
              transaction.accounts.push wallet.getOrCreateAccount(accountIndex)
              io.nodes.push [+accountIndex, +node, +index]
            else
              io.nodes.push undefined
        hasOwn
      transaction.hasOwn = extendIos(transaction.inputs)
      transaction.hasOwn = extendIos(transaction.outputs) or transaction.hasOwn
      _.defer =>
        push null, transaction
        do next
    .fail (error) ->
      push {error, transaction}
      do next
    .done()

  ###
    Filters transactions depending if they belong to the wallet or not.
    @private
  ###
  _filterTransaction: (transaction) ->
    return no if _.isFunction(transaction)
    transaction.hasOwn

  _updateDatabase: (err, transaction, push, next) ->
    # Parse and create operations depending of the transaction. Also create missing accounts
    accounts = _(transaction.accounts)
      .chain()
      .uniq((a) -> a.index)
    .value()
    pulled = no
    ledger.stream(accounts).consume (err, account, push, next) =>
      return push(null, ledger.stream.nil) if account is ledger.stream.nil
      createAccount = =>
        databaseAccount = Account.findById(account.index)
        if !databaseAccount? and pulled
          # Create account
          push null, Account.recoverAccount(account.index, Wallet.instance)
          do next
        else if !databaseAccount?
          # No account found. Try to pull before recovering
          ledger.database.contexts.main.refresh().then ->
            pulled = yes
            createAccount()
          .done()
        else
          # We already have the account
          push null, databaseAccount
          do next
      createAccount()
      return
    .consume (err, account, push, next) =>
      return push(null, ledger.stream.nil) if account is ledger.stream.nil
      inputs = transaction.inputs
      outputs = transaction.outputs
      tx = transaction
      tx.inputs = inputs
      tx.outputs = outputs
      isSending = no
      if _(inputs).chain().some((i) -> _(i.accounts).some((a) -> a?.index is account.getId())).value()
        isSending = yes
        operation = Operation.fromSend(tx, account)
        ledger.app.emit (if operation.isInserted() then 'wallet:operations:update' else 'wallet:operations:new'), [operation]
        operation.save()
        checkForDoubleSpent(operation)
        (transaction.operations ||= []).push operation
      isReception =
        _(transaction.ownOutputs or []).chain().some(
          (o) ->
            a = _(o.accounts).some((a) -> a?.index is account.getId()) and !_(o.nodes).chain().compact().every((n) -> n[1] is 1).value()
            b = !isSending and _(o.accounts).some((a) -> a?.index is account.getId())
            a or b
        ).value()
      if isReception
        operation = Operation.fromReception(tx, account)
        ledger.app.emit (if operation.isInserted() then 'wallet:operations:update' else 'wallet:operations:new'), [operation]
        operation.save()
        checkForDoubleSpent(operation)
        (transaction.operations ||= []).push operation
      do next
    .done =>
      _.defer =>
        @_deferredWait[transaction.hash]?.resolve(transaction)
        @_deferredWait = _(@_deferredWait).omit(transaction.hash)
        #push null, transaction
        do next

  @instance: new @

{$info, $error, $warn} = ledger.utils.Logger.getLazyLoggerByTag("TransactionConsumerTask")

checkForDoubleSpent = (operation) ->
  ledger.tasks.OperationsSynchronizationTask.prototype.checkForDoubleSpent(operation)