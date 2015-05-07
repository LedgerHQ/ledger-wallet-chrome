class @WalletOperationsDetailDialogViewController extends ledger.common.DialogViewController

  show: ->
    @operation = Operation.findById(parseInt(@params['operationId']))
    super

  openBlockchain: ->
    exploreURL = ledger.preferences.instance.getBlockchainExplorerAddress()
    window.open _.str.sprintf(exploreURL, @operation.get('hash'))