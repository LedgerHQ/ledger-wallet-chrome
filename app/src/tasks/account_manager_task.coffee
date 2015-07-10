###
  Listens the database and the HD layout in order to ensure consistency in the database.
###
class ledger.tasks.AccountManagerTask extends ledger.tasks.Task

  @instance: new @

  @reset: -> @instance = new @

  constructor: ->
    super("account_manager_task")

  onStart: ->
    super
    _.bindAll(@, 'onNewHdAccountDiscovered', 'ensureAccountConsistency')
    @ensureAccountConsistency()
    ledger.tasks.TransactionObserverTask.instance.on "discovered:account", @onNewHdAccountDiscovered
    ledger.tasks.WalletLayoutRecoveryTask.instance.on 'bip44:account:done', @ensureAccountConsistency

  onNewHdAccountDiscovered: (ev, {transaction, address, accountIndex}) ->
    @_addAccount(accountIndex)
    Operation.pendingRawTransactionStream().write(transaction)

  ensureAccountConsistency: ->
    wallet = Wallet.instance
    layout = ledger.wallet.Wallet.instance
    if wallet.get('accounts').length < layout.getAccountsCount()
      accountIndexes = _(_(wallet.get('accounts')).map (a) -> a.getId())
      for index in [index...layout.getAccountsCount()] when accountIndexes.contains(index) is false
        if Account.findById(index)?
          # The account isn't bound with the wallet, just link it and save
          wallet.add('account', Account.findById(index)).save()
        else
          @_addAccount(index)

  _addAccount: (index) ->
    unless Account.findById(+accountIndex)?
      account = Account.create({index: index, name: "Recovered ##{index}", hidden: false, color: "#FF0000"}).save()
      Wallet.instance.add('account', account).save()

  onStop: ->
    super
    ledger.tasks.TransactionObserverTask.instance.off "discovered:account", @onNewHdAccountDiscovered
    ledger.tasks.WalletLayoutRecoveryTask.instance.off 'bip44:account:done', @ensureAccountConsistency