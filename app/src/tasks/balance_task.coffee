
singletons = {}

class ledger.tasks.BalanceTask extends ledger.tasks.Task

  constructor: (accountIndex) ->
    super 'balance:' + accountIndex
    @_accountIndex = accountIndex

  onStart: () ->
    @getAccountBalance()

  getAccountBalance: () ->
    @stopIfNeccessary()



  @get: (accountIndex) ->
    unless singletons[accountIndex]?
      singletons[accountIndex] = new @(accountIndex)
    singletons[accountIndex]

  @releaseAllBalanceTasks: -> singletons = {}

  @reset: () ->
    singletons = []