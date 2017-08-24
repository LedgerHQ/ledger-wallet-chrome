class @WalletAccountsAlloperationsViewController extends ledger.common.ActionBarViewController

  view:
    emptyContainer: "#empty_container"
    operationsList: '#operations_list'

  initialize: ->
    super
    @_debouncedUpdateOperations = _.debounce(@_updateOperations, 200, yes)

  onAfterRender: ->
    super
    @_listenEvents()

  onDetach: ->
    super
    ledger.app.off 'wallet:transactions:new wallet:operations:sync:done', @_debouncedUpdateOperations
    ledger.preferences.instance?.off 'currencyActive:changed', @_debouncedUpdateOperations
    ledger.database.contexts.main?.off 'delete:operation', @_debouncedUpdateOperations

  showOperation: (params) ->
    dialog = new WalletDialogsOperationdetailDialogViewController(params)
    dialog.show()

  _updateOperations: ->
    #l 'operations'
    #l Operation.find().where((op) -> true).data()
    
    operations = Operation.find().where((op) -> !op['double_spent_priority']? or op['double_spent_priority'] is 0).sort(Operation.defaultSort).data()
    
    @view.emptyContainer.hide() if operations.length > 0
    render 'wallet/accounts/_operations_table', {operations: operations, showAccounts: true}, (html) =>
      @view.operationsList.html html

  _listenEvents: ->
    # update operations
    @_updateOperations()
    ledger.app.on 'wallet:transactions:new wallet:operations:sync:done', @_debouncedUpdateOperations
    ledger.preferences.instance.on 'currencyActive:changed', @_debouncedUpdateOperations
    ledger.database.contexts.main.on 'delete:operation', @_debouncedUpdateOperations