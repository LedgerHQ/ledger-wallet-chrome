class @WalletSettingsIndexDialogViewController extends DialogViewController

  openHardware: ->
    @getDialog().push new WalletSettingsHardwareSectionDialogViewController()