class @AppsIndexViewController extends ledger.common.ViewController

  openCoinkite: ->
    ledger.app.router.go("/apps/coinkite/dashboard/index")
    @parentViewController.dismiss()

  openBitID: ->
    ledger.app.router.go("/wallet/bitid/form")
    @parentViewController.dismiss()