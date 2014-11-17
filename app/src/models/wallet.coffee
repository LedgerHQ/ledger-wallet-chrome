class @Wallet extends Model
  do @init

  @hasMany accounts: 'Account'

  instance: undefined

  @initializeWallet: (callback) ->
    @instance = @findOrCreate 0,
      accounts: [
        {
          _id: 0
        }
      ]
    callback?()

  @releaseWallet: () ->