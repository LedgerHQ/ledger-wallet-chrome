class @WalletDashboardIndexViewController extends ledger.common.ActionBarViewController

  showOperation: (params) ->
    dialog = new WalletOperationsDetailDialogViewController(params)
    dialog.show()
