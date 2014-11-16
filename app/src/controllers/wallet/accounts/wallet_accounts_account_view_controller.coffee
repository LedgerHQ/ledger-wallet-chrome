class @WalletAccountsAccountViewController extends @ViewController

  badpin: () ->
    ledger.app.wallet.unlockWithPinCode '0001', (success, numberOfRetry) =>
      l success, numberOfRetry

  goodpin: ->
    ledger.app.wallet.unlockWithPinCode '0000', (success) =>
      l success

  setup: ->
    ledger.app.wallet.setup '0000', 'af5920746fad1e40b2a8c7080ee40524a335f129cb374d4c6f82fd6bf3139b17191cb8c38b8e37f4003768b103479947cab1d4f68d908ae520cfe71263b2a0cd', (success) =>
      l success

  bitid: ->
    ledger.app.wallet.getBitIdAddress (address) =>
      @select('#bitid').text(address)

  pub: ->
    ledger.app.wallet.getPublicAddress @select("#deriv").val(), (pubKey, error) =>
      @select('#pk').text(pubKey.bitcoinAddress.value)

  receive: () ->
    dialog = new WalletAccountsAccountReceiveDialogViewController()
    dialog.show()

  send: () ->
    dialog = new WalletAccountsAccountSendDialogViewController()
    dialog.show()

  showOperation: (params) ->
    dialog = new WalletOperationsDetailDialogViewController(params)
    dialog.show()

  onAfterRender: ->
  	#ledger.application.devicesManager.on 'LWWallet.BalanceRecovered', (event, data) ->
    #  l "BALANCE !"
    state = () =>
      ledger.app.wallet.getState (state) =>
        @select("#toto").text(state)
    ledger.app.walletsManager.on 'connected', (ev, wallet) =>
      wallet.on('state:changed', state)
      state()

    @select('#unconfirmed_balance_tooltip').tooltipster
      content: 'Hello world'
      theme: 'tooltipster-light'