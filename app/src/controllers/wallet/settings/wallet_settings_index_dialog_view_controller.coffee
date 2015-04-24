class @WalletSettingsIndexDialogViewController extends DialogViewController

  openHardware: ->
    @getDialog().push new WalletSettingsHardwareSectionDialogViewController()

  openApps: ->
    @getDialog().push new WalletSettingsAppsSectionDialogViewController()

  openDisplay: ->
    @getDialog().push new WalletSettingsDisplaySectionDialogViewController()

  openBitcoin: ->
    @getDialog().push new WalletSettingsBitcoinSectionDialogViewController()

  openTools: ->
    @getDialog().push new WalletSettingsToolsSectionDialogViewController()