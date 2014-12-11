class @WalletAccountsShowViewController extends @ViewController

  view:
    confirmedBalanceSubtitle: '#confirmed_balance_subtitle'
    unconfirmedBalanceSubtitle: '#unconfirmed_balance_subtitle'
    confirmedBalance: '#confirmed_balance'
    unconfirmedBalance: '#unconfirmed_balance'
    emptyContainer: "#empty_container"
    operationsList: '#operations_list'
    accountName: '#account_name'

  onAfterRender: ->
    super
    # fetch balances
    balance = Wallet.instance.getBalance()
    @view.confirmedBalance.text ledger.formatters.bitcoin.fromValue(balance.wallet.total)
    @view.unconfirmedBalance.text ledger.formatters.bitcoin.fromValue(balance.wallet.unconfirmed)

    # listen events
    ledger.app.on 'wallet:balance:changed', (event, balance) =>
      @view.confirmedBalance.text ledger.formatters.bitcoin.fromValue(balance.wallet.total)
      @view.unconfirmedBalance.text ledger.formatters.bitcoin.fromValue(balance.wallet.unconfirmed)

    account = @getAccount()
    @view.accountName.text account.get 'name'

    do @_updateOperations
    ledger.app.on 'wallet:transactions:new wallet:operations:sync:done wallet:operations:new wallet:operations:update', =>
      do @_updateOperations

  showOperation: (params) ->
    dialog = new WalletOperationsDetailDialogViewController(params)
    dialog.show()

  _updateOperations: ->
    operations = @getAccount().get 'operations'
    @view.emptyContainer.hide() if operations.length > 0
    render 'wallet/operations/operations_table', {operations: operations.slice(0, 6)}, (html) =>
      @view.operationsList.html html

  getAccount: () ->
    @_account ?= Account.find(index: 0).first()
    @_account