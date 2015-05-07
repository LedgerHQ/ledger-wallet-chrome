class @WalletDashboardIndexViewController extends ledger.common.ViewController

  showOperation: (params) ->
    dialog = new WalletOperationsDetailDialogViewController(params)
    dialog.show()
