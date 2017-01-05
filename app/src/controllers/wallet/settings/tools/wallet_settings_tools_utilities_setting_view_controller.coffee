class @WalletSettingsToolsUtilitiesSettingViewController extends WalletSettingsSettingViewController

  renderSelector: "#protocols_table_container"

  openRegistration: ->
    window.open "https://www.ledgerwallet.com/wallet/register"
    @parentViewController.dismiss()

  resetApplicationData: ->
    dialog = new CommonDialogsConfirmationDialogViewController()
    dialog.setMessageLocalizableKey 'wallet.settings.tools.resetting_application_data'
    dialog.positiveLocalizableKey = 'common.no'
    dialog.negativeLocalizableKey = 'common.yes'
    dialog.once 'click:negative', =>
      ledger.database.main.delete ->
        chrome.storage.local.clear()
        chrome.runtime.reload()
    dialog.show()

  signMessage: ->
    dialog = new WalletMessageIndexDialogViewController({
      path: "44'/#{ledger.config.network.bip44_coin_type}'/0/0"
      message: ""
      editable: yes
    })
    dialog.show()
    @parentViewController.dismiss()