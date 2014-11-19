
singletons = {}

class ledger.tasks.BalanceTask extends ledger.tasks.Task

  constructor: (accountId) ->
    super 'balance:' + accountId
    @_accountId = accountId

  onStart: () ->
    ledger.api.BalanceRestClient.instance.getAccountBalance @_accountId, (balance, error) =>
      l balance
      return unless @isRunning()
      if error?
        @emit "failure", @
        ledger.app.emit "wallet:balance:failed"
      else
        l balance
        l @_accountId
        a = Account.find(@_accountId).exists (exists) =>
          l exists, a.getUid()
        account = Account.find(@_accountId)
        account.set('total_balance', balance.total)
        account.set('unconfirmed_balance', balance.unconfirmed)
        l account
        account.save =>
          l 'Get'
          account.get ['total_balance'], ->
          @emit "success", @
          ledger.app.emit "wallet:balance:changed",
            wallet:
              total: balance.total
              unconfirmed: balance.unconfirmed
            accounts: [
              {
                total: balance.total
                unconfirmed: balance.unconfirmed
              }
            ]


  @get: (accountId) ->
    unless singletons[accountId]?
      singletons[accountId] = new @(accountId)
    singletons[accountId]

  @releaseAllBalanceTasks: -> singletons = {}