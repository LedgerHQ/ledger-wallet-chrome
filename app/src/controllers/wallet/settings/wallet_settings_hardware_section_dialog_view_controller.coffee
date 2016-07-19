class @WalletSettingsHardwareSectionDialogViewController extends WalletSettingsSectionDialogViewController

  settingViewControllersClasses: [
    WalletSettingsHardwareFirmwareSettingViewController,
    WalletSettingsHardwareSmartphonesSettingViewController
  ]

  onAfterRender: ->
    super
    if ledger.app.dongle.getFirmwareInformation().hasScreenAndButton()
      $('a[href$="#flashFirmware"]').hide()
      $('#smartphones_table_container').hide()