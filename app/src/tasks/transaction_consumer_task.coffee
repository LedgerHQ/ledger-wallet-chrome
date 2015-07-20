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
          e err
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
    l "Started with ", @_input

  onStop: ->
    super
    debugger
    @_input.end()
    @_stream.pause()
    @_stream.end()

  _requestDerivations: ->
    d = ledger.defer()
    ledger.wallet.pathsToAddresses ledger.wallet.Wallet.instance.getAllObservedAddressesPaths(), (addresses) ->
      l "REQUEST DERIVATION ", ledger.wallet.Wallet.instance.getAllObservedAddressesPaths()
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
      l "IN CACHE ", cache
      for io in transaction.inputs.concat(transaction.outputs)
        io.paths = []
        io.accounts = []
        io.nodes = []
        for address in io.addresses
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
    .done()

  ###
    Filters transactions depending if they belong to the wallet or not.
    @private
  ###
  _filterTransaction: (transaction) ->
    accepted = !_(transaction.inputs.concat(transaction.outputs)).chain().map((i) -> i.paths).flatten().compact().isEmpty().value()
    l "Transaction filter", accepted, transaction
    accepted

  _updateLayout: (err, transaction, push, next) ->
    # Notify to the layout that the path is used

    for path in _(transaction.inputs.concat(transaction.outputs)).chain().map((i) -> i.paths).flatten().compact().value()
      l "Notify used ", path
      ledger.wallet.Wallet.instance.getAccountFromDerivationPath(path).notifyPathsAsUsed([path])

    push null, transaction
    do next

  _updateDatabase: (err, transaction, push, next) ->
    # Parse and create operations depending of the transaction. Also create missing accounts
    accounts = _(transaction.inputs.concat(transaction.outputs)).chain().map((io) -> io.accounts).flatten().compact().value()
    l "Accounts ", accounts
    l "Transaction ", transaction
    pulled = no
    ledger.stream(accounts).consume (err, account, push, next) ->
      return push(null, ledger.stream.nil) if account is ledger.stream.nil
      l "Account", account
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
          l "HEY OK SEE NEXT 2"
      createAccount()
      return
    .consume (err, account, push, next) ->
      return push(null, ledger.stream.nil) if account is ledger.stream.nil
      l "Time to add operations"
      inputs = transaction.inputs
      #Filter outputs to remove potential change address
      outputs = _(transaction.outputs).filter((out) -> !_(out.nodes).find((n) -> if n? then n[1] is 1 else no)?)
      tx = _.clone(transaction)
      tx.inputs = inputs
      tx.outputs = outputs
      unless _(inputs).chain().find().isEmpty().value()
        Operation.fromSend(tx)
        #account.add('operations', Operation.fromSend(tx).save()).save()
      unless _(outputs).chain().find().isEmpty().value()
        Operation.fromReception(tx)
        #account.add('operations', Operation.fromReception(tx).save()).save()
      l "HEY OK SEE NEXT 2"
      do next
    .done ->
      "Done perform next"
      push null, transaction
      do next

  @instance: new @

{$info, $error, $warn} = ledger.utils.Logger.getLazyLoggerByTag("TransactionConsumerTask")
