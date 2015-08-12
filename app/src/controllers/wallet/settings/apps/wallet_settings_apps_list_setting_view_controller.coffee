class @WalletSettingsAppsListSettingViewController extends WalletSettingsSettingViewController

  renderSelector: "#list_table_container"

  openCoinkite: ->
    ledger.app.router.go("/apps/coinkite/dashboard/index")
    @parentViewController.dismiss()

  openBitID: ->
    ledger.app.router.go("/wallet/bitid/form")
    @parentViewController.dismiss()