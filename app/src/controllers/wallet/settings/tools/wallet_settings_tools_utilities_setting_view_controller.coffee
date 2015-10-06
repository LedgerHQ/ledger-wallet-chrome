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
      chrome.storage.local.clear()
      chrome.runtime.reload()
    dialog.show()
