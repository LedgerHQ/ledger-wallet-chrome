
class @Operation extends ledger.database.Model
  do @init

  @index 'uid'

  @displayableOperationsChain: (context = ledger.database.contexts.main) ->
    accountIds = _(Account.displayableAccounts(context)).map (a) -> a.index
    Operation.find(account_id: {$in: accountIds}).where(
      (op) -> !op['double_spent_priority']? or op['double_spent_priority'] is 0
    ).sort(@defaultSort)

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
    accountInputs = _(tx.inputs).filter((i) -> _(i.accounts).some((a) -> a? and a.index is index))
    accountOutputs = _(tx.outputs).filter((o) -> _(o.accounts).some((a) -> a? and a.index is index))
    accountChangeOutputs = _(accountOutputs).filter((o) -> _(o.nodes).some((n) -> n?[1] is 1))
    if accountOutputs.length is accountChangeOutputs.length
      inputValue = _(accountInputs).reduce(((m, o) -> m.add(o.value)), ledger.Amount.fromSatoshi(0))
      outputValue = _(accountOutputs).reduce(((m, o) -> m.add(o.value)), ledger.Amount.fromSatoshi(0))
      value = outputValue.subtract(inputValue)
    else
      hasOwnInputs = _(tx.inputs).filter((i) -> _(i.nodes).some((n) -> n?[0] is index)).length > 0
      outputs = _(tx.outputs).filter((o) -> _(o.nodes).some((n) -> (!hasOwnInputs or n?[1] isnt 1) and n?[0] is index))
      value = _(outputs).reduce(((m, o) -> m.add(o.value)), ledger.Amount.fromSatoshi(0))
    @_createOperationFromTransaction(uid, "reception", tx, value, account)

  @_createOperationFromTransaction: (uid, type, tx, value, account) ->
    try
      # Inflate block if possible
      block = Block.fromJson(tx['block'])?.save()
      # Inflate transaction
      transaction = Transaction.fromJson(tx)
      inputs = []
      for i in tx['inputs']
        # Inflate inputs
        input = Input.fromJson(i).save()
        inputs.push input.get('uid')
      transaction.set('inputs_uids', inputs)
      for o in tx['outputs']
        # Inflate outputs
        output = Output.fromJson(tx['hash'], o).save()
        transaction.add('outputs', output)
      transaction.save()
      block?.add('transactions', transaction).save()

      # Inflate operation
      tx.inputs = _(tx.inputs).filter((i) -> i.addresses?)
      tx.outputs = _(tx.outputs).filter((o) -> o.addresses?)
      recipients = _(tx.outputs).chain().filter((o) -> !_(o.nodes).some((n) -> n?[1] is 1)).map((o) -> o.addresses).flatten().value()
      if recipients?.length is 0
        recipients = _(tx.outputs).chain().map((o) -> o.addresses).flatten().value()
      operation = @findOrCreate(uid: uid)
        .set 'type', type
        .set 'value', value.toString()
        .set 'senders', _(tx.inputs).chain().map((i) -> i.addresses).flatten().value()
        .set 'time', (new Date(tx['received_at'] or new Date().getTime())).getTime()
        .set 'recipients', recipients
        .save()
      operation
        .set 'account', account
        .set 'transaction', transaction
        .save()
    catch er
      debugger

  serialize: () ->
    json = super
    delete json['uid']
    return json

  get: (key) ->
    transaction = =>
      transaction._tx if transaction._tx?
      transaction._tx = @get('transaction')
    switch key
      when 'hash' then transaction().get 'hash'
      when 'time' then transaction().get 'received_at'
      when 'confirmations' then transaction().get 'confirmations'
      when 'fees' then transaction().get 'fees'
      when 'total_value'
        if super('type') == 'sending'
          ledger.Amount.fromSatoshi(super 'value').add(transaction().get('fees'))
        else
          super 'value'
      else super key

  @all: (context = ledger.database.contexts.main) ->
    @find({}, context).sort(@defaultSort).data()

  @getUnconfirmedOperations: (context = ledger.database.contexts.main) -> @find(confirmations: $eq: 0, context).data()

  @defaultSort: (a, b) ->
    d = b.time - a.time
    if d is 0
      if a.type > b.type then 1 else -1
    else if d > 0
      1
    else
      -1