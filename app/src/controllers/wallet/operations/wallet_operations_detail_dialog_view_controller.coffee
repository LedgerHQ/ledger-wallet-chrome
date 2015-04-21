class @WalletOperationsDetailDialogViewController extends DialogViewController

  show: ->
    @operation = Operation.findById(parseInt(@params['operationId']))
    super

  openBlockchain: ->
    exploreURL = ledger.preferences.defaults.Bitcoin.explorers[ledger.preferences.instance.getBlockchainExplorer()].address
    window.open _.str.sprintf(exploreURL, @operation.get('hash'))