
singletons = {}

class ledger.tasks.BalanceTask extends ledger.tasks.Task

  constructor: (accountIndex) ->
    super 'balance:' + accountIndex
    @_accountIndex = accountIndex

  onStart: () ->
    @getAccountBalance()

  getAccountBalance: () ->
    account = Account.find(index: @_accountIndex).first()
    totalBalance = account.get 'total_balance'
    unconfirmedBalance = account.get 'unconfirmed_balance'
    account = undefined
    ledger.api.BalanceRestClient.instance.getAccountBalance @_accountIndex, (balance, error) =>
      return unless @isRunning()
      l balance
      if error?
        @emit "failure", @
        ledger.app.emit "wallet:balance:failed"
      else
        account = Account.find(index: @_accountIndex).first()
        account.set('total_balance', balance.total)
        account.set('unconfirmed_balance', balance.unconfirmed)
        account.save()
        @emit "success", @
        if balance.unconfirmed > 0
          _.delay (=> @getAccountBalance()), 1000
        else
          @stopIfNeccessary()
        if totalBalance != balance.total or unconfirmedBalance != balance.unconfirmed
          ledger.app.emit "wallet:balance:changed", account.get('wallet').getBalance()


  @get: (accountIndex) ->
    unless singletons[accountIndex]?
      singletons[accountIndex] = new @(accountIndex)
    singletons[accountIndex]

  @releaseAllBalanceTasks: -> singletons = {}

  @reset: () ->
    singletons = []