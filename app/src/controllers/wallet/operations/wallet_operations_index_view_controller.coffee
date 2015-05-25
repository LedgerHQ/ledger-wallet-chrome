class @WalletOperationsIndexViewController extends ledger.common.ViewController

  view:
    emptyContainer: "#empty_container"
    operationsList: '#operations_list'
    accountName: '#account_name'

  initialize: ->
    super
    @_debouncedUpdateOperations = _.debounce(@_updateOperations, 200, yes)

  onAfterRender: ->
    super
    @_updateAccountName()
    @_listenEvents()

  showOperation: (params) ->
    dialog = new WalletOperationsDetailDialogViewController(params)
    dialog.show()

  _updateOperations: ->
    operations = @_getAccount().get 'operations'
    @view.emptyContainer.hide() if operations.length > 0
    render 'wallet/operations/operations_table', {operations: operations}, (html) =>
      @view.operationsList.html html

  _updateAccountName: ->
    @view.accountName.text(_.str.sprintf(t('wallet.operations.index.title_with_account_name'), @_getAccount().get('name')))

  _listenEvents: ->
    # update operations
    @_updateOperations()
    ledger.app.on 'wallet:transactions:new wallet:operations:sync:done', @_debouncedUpdateOperations
    ledger.preferences.instance.on 'currencyActive:changed', @_debouncedUpdateOperations

  _getAccount: () ->
    @_account ?= Account.find(index: 0).first()
    @_account