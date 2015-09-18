class @WalletSettingsToolsProtocolsSettingViewController extends WalletSettingsSettingViewController

  renderSelector: "#protocols_table_container"

  openRegistration: ->
    window.open "https://www.ledgerwallet.com/wallet/register"
    @parentViewController.dismiss()
