class @WalletAccountsShowViewController extends @ViewController

  view:
    confirmedBalanceSubtitle: '#confirmed_balance_subtitle'
    countervalueBalanceSubtitle: '#countervalue_balance_subtitle'
    confirmedBalance: '#confirmed_balance'
    countervalueBalance: '#countervalue_balance'
    emptyContainer: "#empty_container"
    operationsList: '#operations_list'
    accountName: '#account_name'
    confirmedBalanceContainer: "#confirmed_balance_container"
    countervalueBalanceContainer: "#countervalue_balance_container"

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
    render 'wallet/operations/operations_table', {operations: operations.slice(0, 7)}, (html) =>
      @view.operationsList.html html

  _updateBalances: ->
    total = Wallet.instance.getBalance().wallet.total
    @view.confirmedBalance.text ledger.formatters.fromValue(total)
    @view.countervalueBalance.attr 'data-countervalue', total

  _listenEvents: ->
    # update balance
    @_updateBalances()
    ledger.app.on 'wallet:balance:changed', @_updateBalances

    # update operations
    @_updateOperations()
    ledger.app.on 'wallet:transactions:new wallet:operations:sync:done wallet:operations:new wallet:operations:update', @_updateOperations
    ledger.preferences.instance.on 'currencyActive:changed', @_updateOperations

    # settings
    @_updateCountervalueVisibility()
    ledger.preferences.instance.on 'currencyActive:changed', @_updateCountervalueVisibility

  _updateCountervalueVisibility: ->
    hideCountervalue = !ledger.preferences.instance.isCurrencyActive()
    if hideCountervalue then @view.countervalueBalanceContainer.hide() else @view.countervalueBalanceContainer.show()
    if hideCountervalue then @view.countervalueBalanceSubtitle.hide() else @view.countervalueBalanceSubtitle.show()
    if hideCountervalue then @view.countervalueBalance.removeAttr 'data-countervalue'

  _updateAccountName: ->
    account = @_getAccount()
    @view.accountName.text account.get 'name'

  _updateBalancesLayout: ->
    # invert layout if needed
    if ledger.formatters.symbolIsFirst() then @view.confirmedBalanceContainer.addClass 'inverted' else @view.confirmedBalanceContainer.removeClass 'inverted'

  _getAccount: () ->
    @_account ?= Account.find(index: 0).first()
    @_account