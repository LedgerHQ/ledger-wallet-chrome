class @Transaction extends ledger.database.Model
  do @init

  @index 'hash'
  @has many: 'operations', onDelete: 'destroy'

  ###
  {
      "hash": "da21f9616fb92a7fbe5e72d1537fe30e9b33603d456af72747baf5e5d28f54e3",
      "received_at": "2015-07-06T15:48:58Z",
      "lock_time": 0,
      "fees": 10000
    }
  ###
  @fromJson: (tx, context = ledger.database.contexts.main) ->
    base =
      hash: tx['hash']
      received_at: tx['received_at']
      lock_time: tx['lock_time']
      fees: tx['fees']
    @findOrCreate({hash: base['hash']}, base, context)