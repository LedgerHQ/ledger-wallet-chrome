
class @Operation extends ledger.database.Model
  do @init

  @index 'uid'

  @displayableOperationsChain: (context = ledger.database.contexts.main) ->
    accountIds = _(Account.displayableAccounts(context)).map (a) -> a.index
    Operation.find(account_id: {$in: accountIds}).sort(@defaultSort)

  @fromSend: (tx, account) ->
    index = account.getId()
    uid = "sending#{tx.hash}_#{index}"

    inputs = _(tx.inputs).filter((i) -> _(i.nodes).some((n) -> n?[0] is index))
    value = _(inputs).reduce(((m, i) -> m.add(i.value)), ledger.Amount.fromSatoshi(0))

    changeOutputs = _(tx.outputs).filter((o) -> _(o.nodes).some((n) -> n?[1] is 1 and n?[0] is index))
    changeValue = _(changeOutputs).reduce(((m, o) -> m.add(o.value)), ledger.Amount.fromSatoshi(0))
    @_createOperationFromTransaction(uid, "sending", tx, value.subtract(tx.fees).subtract(changeValue), account)

  @fromReception: (tx, account) ->
    index = account.getId()
    uid = "reception_#{tx.hash}_#{index}"
    outputs = _(tx.outputs).filter((o) -> _(o.nodes).some((n) -> n?[1] isnt 1 and n?[0] is index))
    value = _(outputs).reduce(((m, o) -> m.add(o.value)), ledger.Amount.fromSatoshi(0))
    @_createOperationFromTransaction(uid, "reception", tx, value, account)

  @_createOperationFromTransaction: (uid, type, tx, value, account) ->
    @findOrCreate(uid: uid)
      .set 'hash', tx['hash']
      .set 'fees', tx['fees']
      .set 'time', (new Date(tx['chain_received_at'] or new Date().getTime())).getTime()
      .set 'type', type
      .set 'value', value.toString()
      .set 'confirmations', tx['confirmations']
      .set 'senders', _(tx.inputs).chain().map((i) -> i.addresses).flatten().value()
      .set 'recipients', _(tx.outputs).chain().filter((o) -> !_(o.nodes).some((n) -> n?[1] is 1)).map((o) -> o.addresses).flatten().value()
      .set 'account', account

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