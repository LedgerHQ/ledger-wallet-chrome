class @WalletAccountsShowViewController extends ledger.common.ActionBarViewController

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
    colorCircle: '#color_circle'

  breadcrumb: null

  actions: [
    { title: 'wallet.accounts.show.actions.see_all_operations', icon: 'fa-reorder', url: '/wallet/accounts/:account_id:/operations'}
    { title: 'wallet.accounts.show.actions.account_settings', icon: 'fa-cog', url: '#openSettings'}
  ]

  initialize: ->
    super
    @_debouncedUpdateOperations = _.debounce(@_updateOperations, 200)
    @_debouncedUpdateBalances = _.debounce(@_updateBalances, 200)
    @_debouncedUpdateCountervalueVisibility = _.debounce(@_updateCountervalueVisibility, 200)
    @actions = _.clone(@actions)
    @actions[0].url = "/wallet/accounts/#{@_getAccount().get('index')}/operations"
    @_updateBreadcrumb()

  onAfterRender: ->
    super
    @_updateBalancesLayout()
    @_updateAccountName()
    @_listenEvents()

  showOperation: (params) ->
    dialog = new WalletDialogsOperationdetailDialogViewController(params)
    dialog.show()

  openSettings: ->
    (new WalletDialogsAccountsettingsDialogViewController(account_id: @_getAccount().get('index'))).show()

  onDetach: ->
    # update balance
    ledger.app.off 'wallet:balance:changed', @_debouncedUpdateBalances

    # update operations
    ledger.app.off 'wallet:transactions:new wallet:operations:sync:done wallet:operations:new wallet:operations:update', @_debouncedUpdateOperations
    ledger.preferences.instance?.off 'currencyActive:changed', @_debouncedUpdateOperations
    ledger.database.contexts.main.off 'delete:operation', @_debouncedUpdateOperations

    # settings
    ledger.preferences.instance?.off 'currencyActive:changed', @_debouncedUpdateCountervalueVisibility

    # listen accounts
    ledger.database.contexts.main.off 'update:account insert:account remove:account', @_updateAccountName

  _updateBreadcrumb: ->
    @breadcrumb = [{ title: 'wallet.breadcrumb.accounts', url: '/wallet/accounts'}]
    @breadcrumb.push title: @_getAccount().get('name'), url: @routedUrl
    @parentViewController?.updateActionBar()

  _updateOperations: ->
    operations = @_getAccount().get 'operations'
    operations = _(operations).filter((op) -> !op.get('double_spent_priority')? or op.get('double_spent_priority') is 0)
    @view.emptyContainer.hide() if operations.length > 0
    render 'wallet/accounts/_operations_table', {operations: operations.slice(0, 6), showAddresses: true}, (html) =>
      @view.operationsList.html html

  _updateBalances: ->
    total = @_getAccount().get('total_balance')
    @view.confirmedBalance.text ledger.formatters.fromValue(total)
    @view.countervalueBalance.attr 'data-countervalue', total

  _listenEvents: ->
    # update balance
    @_updateBalances()
    ledger.app.on 'wallet:balance:changed', @_debouncedUpdateBalances

    # update operations
    @_updateOperations()
    ledger.app.on 'wallet:transactions:new wallet:operations:sync:done wallet:operations:new wallet:operations:update', @_debouncedUpdateOperations
    ledger.database.contexts.main.on 'delete:operation', @_debouncedUpdateOperations
    ledger.preferences.instance.on 'currencyActive:changed', @_debouncedUpdateOperations

    # settings
    @_updateCountervalueVisibility()
    ledger.preferences.instance.on 'currencyActive:changed', @_debouncedUpdateCountervalueVisibility

    # listen accounts
    ledger.database.contexts.main.on 'update:account insert:account remove:account', @_updateAccountName

  _updateCountervalueVisibility: ->
    hideCountervalue = !ledger.preferences.instance.isCurrencyActive()
    if hideCountervalue then @view.countervalueBalanceContainer.hide() else @view.countervalueBalanceContainer.show()
    if hideCountervalue then @view.countervalueBalanceSubtitle.hide() else @view.countervalueBalanceSubtitle.show()
    if hideCountervalue then @view.countervalueBalance.removeAttr 'data-countervalue'

  _updateAccountName: ->
    account = @_getAccount()
    @view.accountName.text account.get 'name'
    @view.colorCircle.css('color', account.get('color'))
    @_updateBreadcrumb()

  _updateBalancesLayout: ->
    # invert layout if needed
    if ledger.formatters.symbolIsFirst() then @view.confirmedBalanceContainer.addClass 'inverted' else @view.confirmedBalanceContainer.removeClass 'inverted'

  _getAccount: () ->
    @_accountId ||= +@routedUrl.match(/wallet\/accounts\/(\d+)\/show/)[1]
    @_account ?= Account.find(index: @_accountId).first()
    @_account