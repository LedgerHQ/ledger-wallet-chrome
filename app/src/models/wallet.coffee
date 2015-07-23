class @Wallet extends ledger.database.Model
  do @init

  #@hasMany accounts: 'Account'
  @has many: 'accounts', sortBy: 'index', onDelete: 'destroy'
  @index 'id', sync: yes

  @instance: undefined

  ## Global Balance management

  retrieveAccountsBalances: () ->
    for account in @get('accounts')
      account.retrieveBalance()

  getBalance: () ->
    balance =
      wallet:
        total: ledger.Amount.fromSatoshi(0)
        unconfirmed: ledger.Amount.fromSatoshi(0)
      accounts: []

    for account in @get('accounts')
      continue if not account.get('total_balance')? or not account.get('unconfirmed_balance')?
      balance.wallet.total = balance.wallet.total.add(account.get('total_balance'))
      balance.wallet.unconfirmed = balance.wallet.unconfirmed.add(account.get('unconfirmed_balance'))
      balance.accounts.push total: account.get('total_balance'), unconfirmed: account.get('unconfirmed_balance')

    balance

  ## Lifecyle

  @initializeWallet: (callback) ->
    @instance = @findOrCreate(1, {id: 1}).save()
    callback?()

  @releaseWallet: () ->
