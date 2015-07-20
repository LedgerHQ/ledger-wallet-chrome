
class @Operation extends ledger.database.Model
  do @init

  @index 'uid'

  @pendingRawTransactionStream: () ->
    @_pendingRawTransactionStream ?= new Stream().open()
    @_pendingRawTransactionStream

  @displayableOperationsChain: (context = ledger.database.contexts.main) ->
    accountIds = _(Account.displayableAccounts(context)).map (a) -> a.index
    Operation.find(account_id: {$in: accountIds}).sort(@defaultSort)

  @fromSend: (tx) ->
    l "Sended transaction ", tx

  @fromReception: (tx) ->
    l "Received transaction ", tx

  serialize: () ->
    json = super
    delete json['uid']
    return json

  get: (key) ->
    switch key
      when 'total_value'
        if super('type') == 'sending'
          ledger.Amount.fromSatoshi(super 'value').add(super 'fees')
        else
          super 'value'
      else super key

  @all: (context = ledger.database.contexts.main) ->
    @find({}, context).sort(@defaultSort).data()

  @defaultSort: (a, b) ->
    d = b.time - a.time
    if d is 0
      if a.type > b.type then 1 else -1
    else if d > 0
      1
    else
      -1