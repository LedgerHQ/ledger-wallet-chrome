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
    @_input = highland()
    @_stream = @_input
      .consume(@_extendTransaction.bind(@))
      .filter(@_filterTransaction.bind(@))
      .consume(@_updateLayout.bind(@))
      .consume(@_updateDatabase.bind(@))

  ###
    Push a single json formatted transaction into the stream.
  ###
  pushTransaction: (transaction) ->
    unless transaction?
      $warn "Transaction consumer received a null transaction.", new Error().stack
      return
    @_input.write(transaction)
    @

  ###
    Push an array of json formatted transactions into the stream.
  ###
  pushTransactions: (transactions) ->
    isPaused = @_input.paused
    @_input.pause() unless isPaused
    @pushTransactions(transaction) for transaction in transactions
    @_input.resume() unless isPaused
    @

  ###
    Get a forked version of the transaction stream
  ###
  fork: -> @_stream.fork()

  onStart: ->
    super
    @_stream.resume()
    @_stream.each(@_updateLayout.bind(@)).each(@_updateDatabase.bind(@))

  onStop: ->
    super
    @_stream.pause()
    @_stream.end()

  _requestDerivations: ->
    d = ledger.defer()
    ledger.wallet.pathsToAddresses ledger.wallet.Wallet.instance.getAllObservedAddressesPaths(), (addresses) ->
      d.resolve(_.invert(addresses))
    d.promise

  _getAddressCache: ->
    @_cachePromise ||= do => @_requestDerivations()

  _notifyNewPathAreAvailable: ->
    return unless @_cachePromise?
    @_cachePromise = null
    @_getAddressCache()
    return

  ###
    Extends the given transaction with derivation paths
    @private
  ###
  _extendTransaction: (err, transaction, push, next) ->
    @_getAddressCache().then =>

      transaction


  ###
    Filters transactions depending if they belong to the wallet or not.
    @private
  ###
  _filterTransaction: (transaction) ->
    !_(transaction.inputs.concat(transaction.outputs)).chain().map((i) -> i.paths).flatten().isEmpty().value()

  _updateLayout: (err, transaction, push, next) ->
    # Notify to the layout that the path is used

  _updateDatabase: (err, transaction, push, next) ->
    # Parse and create operations depending of the transaction. Also create missing accounts



  @instance: new @

{$info, $error, $warn} = ledger.utils.Logger.getLazyLoggerByTag("TransactionConsumerTask")
