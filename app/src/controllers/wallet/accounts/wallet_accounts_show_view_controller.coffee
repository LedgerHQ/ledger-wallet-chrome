class @WalletAccountsShowViewController extends @ViewController

  view:
    confirmedBalanceSubtitle: '#confirmed_balance_subtitle'
    unconfirmedBalanceSubtitle: '#unconfirmed_balance_subtitle'
    emptyContainer: "#empty_container"

  onAfterRender: ->
    super
    @view.emptyContainer.hide()