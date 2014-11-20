class @Wallet extends Model
  do @init

  @hasMany accounts: 'Account'

  instance: undefined

  ## Global Balance management

  retrieveAccountsBalances: () ->
    @getAccounts (accounts) =>
      accounts.each (account) =>
        _.model(account).retrieveBalance() if account?

  getBalance: (callback = _.noop) ->
    balance =
      wallet:
        total: 0
        unconfirmed: 0
      accounts: []

    @getAccounts (accounts) =>
      accounts.each (account) =>
        if account?
          balance.wallet.total += account.total_balance
          balance.wallet.unconfirmed += account.unconfirmed_balance
          balance.accounts.push total: account.total_balance, unconfirmed: account.unconfirmed_balance
        else
          callback(balance)


  ## Lifecyle

  @initializeWallet: (callback) ->
    @instance = @find(0)
    _.defer =>
      @instance.exists (exists) =>
        if exists is true
          callback?()
        else
          @instance = Wallet.create({_id: 0, accounts: []})
          @instance.save =>
            account = Account.create {_id: 0, name: t 'common.default_account_name'}
            account.save =>
              @instance.getAccounts (accounts) =>
                accounts.insert account, =>
                  accounts.toArray (a) => l a
                  callback?()

  @releaseWallet: () ->
