class @WalletAccountsOperationsViewController extends ledger.common.ActionBarViewController

  view:
    emptyContainer: "#empty_container"
    operationsList: '#operations_list'
    accountName: '#account_name'
    colorCircle: "#color_circle"

  initialize: ->
    super
    @_debouncedUpdateOperations = _.debounce(@_updateOperations, 200, yes)

  onAfterRender: ->
    super
    @_updateAccountName()
    @_listenEvents()

  onDetach: ->
    super
    ledger.app.off 'wallet:transactions:new wallet:operations:sync:done', @_debouncedUpdateOperations
    ledger.preferences.instance?.off 'currencyActive:changed', @_debouncedUpdateOperations

  showOperation: (params) ->
    dialog = new WalletDialogsOperationdetailDialogViewController(params)
    dialog.show()

  _updateOperations: ->
    operations = @_getAccount().get 'operations'
    @view.emptyContainer.hide() if operations.length > 0
    render 'wallet/accounts/_operations_table', {operations: operations}, (html) =>
      @view.operationsList.html html

  _updateAccountName: ->
    @view.accountName.text(_.str.sprintf(t('wallet.accounts.operations.all_account_operations'), @_getAccount().get('name')))
    @view.colorCircle.css('color', @_getAccount().get('color'))

  _listenEvents: ->
    # update operations
    @_updateOperations()
    ledger.app.on 'wallet:transactions:new wallet:operations:sync:done', @_debouncedUpdateOperations
    ledger.preferences.instance.on 'currencyActive:changed', @_debouncedUpdateOperations

  _getAccount: () -> @_account ||= Account.findById(+@routedUrl.match(/wallet\/accounts\/(\d+)\/operations/)[1])