
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
        account = Account.find(@_accountId)
        account.set('total_balance', balance.total)
        account.set('unconfirmed_balance', balance.unconfirmed)
        l account
        account.save =>
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