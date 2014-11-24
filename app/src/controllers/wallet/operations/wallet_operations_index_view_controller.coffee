class @WalletOperationsIndexViewController extends ViewController

  view:
    emptyContainer: "#empty_container"
    operationsList: '#operations_list'
    accountName: '#account_name'

  onAfterRender: ->
    super
    account = Account.find(0).exists =>
      account.get (data) =>
        @view.accountName.text(_.str.sprintf(t('wallet.operations.index.title_with_account_name'), data.name))

    do @_updateOperations
    ledger.app.on 'wallet:transactions:new wallet:operations:sync:done', =>
      do @_updateOperations

  showOperation: (params) ->
    dialog = new WalletOperationsDetailDialogViewController(params)
    dialog.show()

  _updateOperations: ->
    Account.find(0).getAllSortedOperations (operations) =>
      @view.emptyContainer.hide() if operations.length > 0
      render 'wallet/operations/operations_table', {operations: operations}, (html) =>
        @view.operationsList.html html