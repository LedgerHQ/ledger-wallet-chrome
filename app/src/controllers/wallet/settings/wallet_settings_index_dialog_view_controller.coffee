class @WalletSettingsIndexDialogViewController extends DialogViewController

  openHardware: ->
    @getDialog().push new WalletSettingsHardwareSectionDialogViewController()

  openApps: ->
    @getDialog().push new WalletSettingsAppsSectionDialogViewController()