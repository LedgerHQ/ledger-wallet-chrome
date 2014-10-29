class @WalletAccountsAccountViewController extends @ViewController

  showOperation: (params) ->
    dialog = new WalletOperationsDetailDialogViewController(params)
    dialog.show()

  onAfterRender: ->
    @select('#unconfirmed_balance_tooltip').tooltipster
      content: 'Hello world'
      theme: 'tooltipster-light'