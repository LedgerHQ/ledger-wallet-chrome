class @WalletDashboardIndexViewController extends @ViewController

  showOperation: (params) ->
    dialog = new WalletOperationsDetailDialogViewController(params)
    dialog.show()
