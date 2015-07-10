class @WalletAccountsIndexViewController extends ledger.common.ActionBarViewController

  view:
    emptyContainer: "#empty_container"
    operationsList: '#operations_list'
    accountsList: '#accounts_list'

  actions: [
    {title: 'wallet.accounts.index.actions.add_account', icon: 'fa-plus', url: '#addAccount'}
    {title: 'wallet.accounts.index.actions.see_all_operations', icon: 'fa-bars', url: '/wallet/accounts/alloperations'}
  ]

  initialize: ->
    super
    @_debouncedUpdateAccounts = _.debounce(@_updateAccounts, 200)
    @_debouncedUpdateOperations = _.debounce(@_updateOperations, 200)

  onAfterRender: ->
    super
    @_updateAccounts()
    @_updateOperations()
    @_listenEvents()

  addAccount: -> (new WalletDialogsAddaccountDialogViewController()).show()

  showOperation: (params) -> (new WalletDialogsOperationdetailDialogViewController(params)).show()

  _listenEvents: ->
    # listen balance
    ledger.app.on 'wallet:balance:changed', @_debouncedUpdateAccounts

    # listen operations
    ledger.app.on 'wallet:transactions:new wallet:operations:sync:done wallet:operations:new wallet:operations:update', @_debouncedUpdateOperations
    ledger.preferences.instance.on 'currencyActive:changed', @_debouncedUpdateOperations

    # listen preferences
    ledger.preferences.instance.on 'currencyActive:changed', @_debouncedUpdateAccounts

    # listen accounts
    ledger.database.contexts.main.on 'update:account insert:account remove:account', @_debouncedUpdateAccounts
    ledger.database.contexts.main.on 'update:account insert:account remove:account', @_debouncedUpdateOperations

  _updateOperations: ->
    operations = Operation.chain().sort(Operation.defaultSort).limit(6).data()
    @view.emptyContainer.hide() if operations.length > 0
    render 'wallet/accounts/_operations_table', {operations: operations, showAccounts: true}, (html) =>
      @view.operationsList.html html

  _updateAccounts: ->
    accounts = Account.displayableAccounts()
    render 'wallet/accounts/_accounts_list', {accounts: accounts}, (html) =>
      @view.accountsList.html html