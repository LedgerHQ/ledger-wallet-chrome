class @WalletDashboardOperationsViewController extends ledger.common.ActionBarViewController

  view:
    emptyContainer: "#empty_container"
    operationsList: '#operations_list'
    accountName: '#account_name'

  initialize: ->
    super
    @_debouncedUpdateOperations = _.debounce(@_updateOperations, 200, yes)

  onAfterRender: ->
    super
    @_listenEvents()

  onDetach: ->
    super
    ledger.app.off 'wallet:transactions:new wallet:operations:sync:done', @_debouncedUpdateOperations
    ledger.preferences.instance.off 'currencyActive:changed', @_debouncedUpdateOperations

  showOperation: (params) ->
    dialog = new WalletOperationsDetailDialogViewController(params)
    dialog.show()

  _updateOperations: ->
    operations = Operation.all()
    @view.emptyContainer.hide() if operations.length > 0
    render 'wallet/operations/operations_table', {operations: operations}, (html) =>
      @view.operationsList.html html

  _listenEvents: ->
    # update operations
    @_updateOperations()
    ledger.app.on 'wallet:transactions:new wallet:operations:sync:done', @_debouncedUpdateOperations
    ledger.preferences.instance.on 'currencyActive:changed', @_debouncedUpdateOperations
