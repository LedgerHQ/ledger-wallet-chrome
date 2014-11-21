class @WalletAccountsShowViewController extends @ViewController

  view:
    confirmedBalanceSubtitle: '#confirmed_balance_subtitle'
    unconfirmedBalanceSubtitle: '#unconfirmed_balance_subtitle'
    confirmedBalance: '#confirmed_balance'
    unconfirmedBalance: '#unconfirmed_balance'
    emptyContainer: "#empty_container"
    operationsList: '#operations_list'
    accountName: '#account_name'

  onAfterRender: ->
    super
    # fetch balances
    Wallet.instance.getBalance (balance) =>
      @view.confirmedBalance.text ledger.formatters.bitcoin.fromValue(balance.wallet.total)
      @view.unconfirmedBalance.text ledger.formatters.bitcoin.fromValue(balance.wallet.unconfirmed)

    # listen events
    ledger.app.on 'wallet:balance:changed', (event, balance) =>
      @view.confirmedBalance.text ledger.formatters.bitcoin.fromValue(balance.wallet.total)
      @view.unconfirmedBalance.text ledger.formatters.bitcoin.fromValue(balance.wallet.unconfirmed)

    account = Account.find(0).exists =>
      account.get (data) =>
        @view.accountName.text data.name

    do @_updateOperations
    ledger.app.on 'wallet:transactions:new wallet:operations:sync:done', =>
      do @_updateOperations

  _updateOperations: ->
    Account.find(0).getAllSortedOperations (operations) =>
      @view.emptyContainer.hide() if operations.length > 0
      render 'wallet/operations/operations_table', {operations: operations.slice(0, 6)}, (html) =>
        @view.operationsList.html html