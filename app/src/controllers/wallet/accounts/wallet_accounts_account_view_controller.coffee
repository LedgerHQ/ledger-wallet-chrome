class @WalletAccountsAccountViewController extends @ViewController

  receive: () ->
    dialog = new WalletAccountsAccountReceiveDialogViewController()
    dialog.show()

  send: () ->
    l 'send'

  showOperation: (params) ->
    dialog = new WalletOperationsDetailDialogViewController(params)
    dialog.show()

  onAfterRender: ->
  	#ledger.application.devicesManager.on 'LWWallet.BalanceRecovered', (event, data) ->
    #  l "BALANCE !"

    @select('#unconfirmed_balance_tooltip').tooltipster
      content: 'Hello world'
      theme: 'tooltipster-light'