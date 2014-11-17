class @Wallet extends Model
  do @init

  @hasMany accounts: 'Account'

  instance: undefined

  @initializeWallet: (callback) ->
    callback?()

  @releaseWallet: () ->