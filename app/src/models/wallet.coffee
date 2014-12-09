class @Wallet extends Model
  do @init

  #@hasMany accounts: 'Account'
  @has many: 'accounts', sortBy: 'index', onDelete: 'destroy'

  @instance: undefined

  ## Global Balance management

  retrieveAccountsBalances: () ->
    for account in @get('accounts')
      account.retrieveBalance()

  getBalance: () ->
    balance =
      wallet:
        total: 0
        unconfirmed: 0
      accounts: []

    for account in @get('accounts')
      continue if not account.get('total_balance')? or not account.get('unconfirmed_balance')?
      balance.wallet.total += account.get('total_balance')
      balance.wallet.unconfirmed += account.get('unconfirmed_balance')
      balance.accounts.push total: account.get('total_balance'), unconfirmed: account.get('unconfirmed_balance')

    balance

  ## Lifecyle

  @initializeWallet: (callback) ->
    @instance = @findOrCreate(1, {id: 1})
    if @instance.isInserted()
      callback?()
    else
      @instance.add('accounts', {index: 0, name: t 'common.default_account_name'}).save()
      callback?()

  @releaseWallet: () ->
