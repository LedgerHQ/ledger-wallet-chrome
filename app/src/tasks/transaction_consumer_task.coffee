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

###
class ledger.tasks.TransactionConsumerTask extends ledger.tasks.Task

  @reset: -> @instance = new @

  constructor: ->
    super 'global_transaction_consumer'

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
      .consume(safe(@_updateLayout.bind(@)))
      .consume(safe(@_updateDatabase.bind(@)))

    @_errorInput = ledger.stream()
    @_errorStream = ledger.stream(@_errorInput)

  ###
    Push a single json formatted transaction into the stream.
  ###
  pushTransaction: (transaction) ->
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
    wallet = ledger.wallet.Wallet.instance
    @_getAddressCache().then (cache) =>
      for io in transaction.inputs.concat(transaction.outputs)
        io.paths = []
        io.accounts = []
        io.nodes = []
        for address in (io.addresses or [])
          path = cache[address]
          io.paths.push path
          io.accounts.push (if path? then wallet.getOrCreateAccountFromDerivationPath(path) else undefined)
          if path?
            [__, accountIndex, node, index] = path.match("#{wallet.getRootDerivationPath()}/(\\d+)'/(0|1)/(\\d+)")
            io.nodes.push [+accountIndex, +node, +index]
          else
            io.nodes.push undefined
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
    !_(transaction.inputs.concat(transaction.outputs)).chain().map((i) -> i.paths).flatten().compact().isEmpty().value()

  _updateLayout: (err, transaction, push, next) ->
    # Notify to the layout that the path is used

    for path in _(transaction.inputs.concat(transaction.outputs)).chain().map((i) -> i.paths).flatten().compact().value()
      ledger.wallet.Wallet.instance.getAccountFromDerivationPath(path).notifyPathsAsUsed([path])

    push null, transaction
    do next

  _updateDatabase: (err, transaction, push, next) ->
    # Parse and create operations depending of the transaction. Also create missing accounts
    accounts = _(transaction.inputs.concat(transaction.outputs))
      .chain()
      .map((io) -> io.accounts)
      .flatten()
      .compact()
      .uniq((a) -> a.index)
    .value()
    pulled = no
    ledger.stream(accounts).consume (err, account, push, next) ->
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
    .consume (err, account, push, next) ->
      return push(null, ledger.stream.nil) if account is ledger.stream.nil
      inputs = transaction.inputs
      outputs = transaction.outputs
      tx = _.clone(transaction)
      tx.inputs = inputs
      tx.outputs = outputs
      if _(inputs).chain().some((i) -> _(i.accounts).some((a) -> a?.index is account.getId())).value()
        operation = Operation.fromSend(tx, account)
        ledger.app.emit (if operation.isInserted() then 'wallet:operations:update' else 'wallet:operations:new'), [operation]
        operation.save()
        (transaction.operations ||= []).push operation
      if _(outputs).chain().some((o) -> _(o.accounts).some((a) -> a?.index is account.getId()) and !_(o.nodes).chain().compact().every((n) -> n[1] is 1).value()).value()
        operation = Operation.fromReception(tx, account)
        ledger.app.emit (if operation.isInserted() then 'wallet:operations:update' else 'wallet:operations:new'), [operation]
        operation.save()
        (transaction.operations ||= []).push operation
      do next
    .done ->
      push null, transaction
      do next

  @instance: new @

{$info, $error, $warn} = ledger.utils.Logger.getLazyLoggerByTag("TransactionConsumerTask")
