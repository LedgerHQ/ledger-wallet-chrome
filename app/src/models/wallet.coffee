class @Wallet extends Model
  do @init

  @hasMany accounts: 'Account'
