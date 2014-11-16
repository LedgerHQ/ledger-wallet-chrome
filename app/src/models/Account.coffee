class @Account extends Model
  do @init

  @hasMany operations: 'Operations'

  createTransaction: (amount, fees, callback) ->
    transaction = new ledger.wallet.Transaction()
    transaction.init amount, fees