class @WalletAccountsShowViewController extends @ViewController

  view:
    confirmedBalanceSubtitle: '#confirmed_balance_subtitle'
    unconfirmedBalanceSubtitle: '#unconfirmed_balance_subtitle'
    confirmedBalance: '#confirmed_balance'
    unconfirmedBalance: '#unconfirmed_balance'
    emptyContainer: "#empty_container"
    operationsList: '#operations_list'
    accountName: '#account_name'
    confirmedBalanceContainer: "#confirmed_balance_container"
    unconfirmedBalanceContainer: "#unconfirmed_balance_container"

  onAfterRender: ->
    super
    @_updateBalancesLayout()
    @_updateAccountName()
    @_listenEvents()

  showOperation: (params) ->
    dialog = new WalletOperationsDetailDialogViewController(params)
    dialog.show()

  _updateOperations: ->
    operations = @_getAccount().get 'operations'
    @view.emptyContainer.hide() if operations.length > 0
    render 'wallet/operations/operations_table', {operations: operations.slice(0, 6)}, (html) =>
      @view.operationsList.html html

  _updateBalances: ->
    @view.confirmedBalance.text ledger.formatters.fromValue(Wallet.instance.getBalance().wallet.total)
    @view.unconfirmedBalance.text ledger.formatters.formatValue(Wallet.instance.getBalance().wallet.unconfirmed)
    hideUnconfirmed = Wallet.instance.getBalance().wallet.unconfirmed == 0
    if hideUnconfirmed then @view.unconfirmedBalanceContainer.hide() else @view.unconfirmedBalanceContainer.show()
    if hideUnconfirmed then @view.unconfirmedBalanceSubtitle.hide() else @view.unconfirmedBalanceSubtitle.show()

  _listenEvents: ->
    # update balances
    @_updateBalances()
    ledger.app.on 'wallet:balance:changed', @_updateBalances

    # update operations
    @_updateOperations()
    ledger.app.on 'wallet:transactions:new wallet:operations:sync:done wallet:operations:new wallet:operations:update', @_updateOperations
    ledger.preferences.instance.on 'currencyActive:changed', @_updateOperations

  _updateAccountName: ->
    account = @_getAccount()
    @view.accountName.text account.get 'name'

  _updateBalancesLayout: ->
    # invert layout if needed
    if ledger.formatters.symbolIsFirst() then @view.confirmedBalanceContainer.addClass 'inverted' else @view.confirmedBalanceContainer.removeClass 'inverted'

  _getAccount: () ->
    @_account ?= Account.find(index: 0).first()
    @_account