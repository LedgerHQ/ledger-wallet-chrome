class @WalletOperationsIndexViewController extends ViewController

  view:
    emptyContainer: "#empty_container"
    operationsList: '#operations_list'
    accountName: '#account_name'

  onAfterRender: ->
    super
    @view.accountName.text(_.str.sprintf(t('wallet.operations.index.title_with_account_name'), @getAccount().get('name')))

    do @_updateOperations
    ledger.app.on 'wallet:transactions:new wallet:operations:sync:done', =>
      do @_updateOperations

  showOperation: (params) ->
    dialog = new WalletOperationsDetailDialogViewController(params)
    dialog.show()

  _updateOperations: ->
    operations = @getAccount().get 'operations'
    @view.emptyContainer.hide() if operations.length > 0
    render 'wallet/operations/operations_table', {operations: operations}, (html) =>
      @view.operationsList.html html

  getAccount: () ->
    @_account ?= Account.find(index: 0).first()
    @_account