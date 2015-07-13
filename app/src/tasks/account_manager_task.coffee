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
    ledger.tasks.WalletLayoutRecoveryTask.instance.on 'bip44:done', @ensureAccountConsistency

  onNewHdAccountDiscovered: (ev, {transaction, address, accountIndex}) ->
    @_addAccount(accountIndex)
    Operation.pendingRawTransactionStream().write(transaction)

  ensureAccountConsistency: ->
    l "ensureAccountConsistency ", arguments
    wallet = Wallet.instance
    layout = ledger.wallet.Wallet.instance
    l "Ensure consitency wallet: #{wallet.get('accounts').length}, layout: #{layout.getAccountsCount()}, db: ", Account.all()
    if wallet.get('accounts').length < layout.getAccountsCount()
      accountIndexes = _(wallet.get('accounts')).map (a) -> a.getId()
      for index in [0...layout.getAccountsCount()] when !_(accountIndexes).contains(index) and !layout.getAccount(index).isEmpty()
        if Account.findById(index)?
          # The account isn't bound with the wallet, just link it and save
          wallet.add('accounts', Account.findById(index)).save()
        else
          @_addAccount(index)

  _addAccount: (index) ->
    unless Account.findById(+index)?
      account = Account.create({index: index, name: "Recovered ##{index}", hidden: false, color: "#FF0000"}).save()
      Wallet.instance.add('accounts', account).save()

  onStop: ->
    super
    ledger.tasks.TransactionObserverTask.instance.off "discovered:account", @onNewHdAccountDiscovered
    ledger.tasks.WalletLayoutRecoveryTask.instance.off 'bip44:account:done', @ensureAccountConsistency