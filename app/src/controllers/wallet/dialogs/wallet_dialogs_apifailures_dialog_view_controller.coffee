class @WalletDialogsApifailuresDialogViewController extends ledger.common.DialogViewController

  openHelpCenter: ->
    window.open t 'application.support_url'
    @dismiss()
