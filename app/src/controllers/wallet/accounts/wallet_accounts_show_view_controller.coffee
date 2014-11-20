class @WalletAccountsShowViewController extends @ViewController

  view:
    confirmedBalanceSubtitle: '#confirmed_balance_subtitle'
    unconfirmedBalanceSubtitle: '#unconfirmed_balance_subtitle'
    confirmedBalance: '#confirmed_balance'
    unconfirmedBalance: '#unconfirmed_balance'
    emptyContainer: "#empty_container"

  onAfterRender: ->
    super
    @view.emptyContainer.hide()
    # fetch balances
    Wallet.instance.getBalance (balance) =>
      @view.confirmedBalance.text ledger.formatters.bitcoin.fromValue(balance.wallet.total)
      @view.unconfirmedBalance.text ledger.formatters.bitcoin.fromValue(balance.wallet.unconfirmed)

    # listen events
    ledger.app.on 'wallet:balance:changed', (event, balance) =>
      @view.confirmedBalance.text ledger.formatters.bitcoin.fromValue(balance.wallet.total)
      @view.unconfirmedBalance.text ledger.formatters.bitcoin.fromValue(balance.wallet.unconfirmed)