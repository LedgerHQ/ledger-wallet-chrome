class @WalletSettingsHardwareFirmwareSettingViewController extends WalletSettingsSettingViewController

  renderSelector: "#firmware_table_container"
  view:
    currentVersionText: "#current_version_text"
    updateAvailabilityText: "#update_availability_text"

  onAfterRender: ->
    super
    @_refreshFirmwareStatus()

  flashFirmware: ->
    dialog = new CommonDialogsConfirmationDialogViewController()
    dialog.setMessageLocalizableKey 'common.errors.going_to_firmware_update'
    dialog.once 'click:negative', =>
      ledger.app.setExecutionMode(ledger.app.Modes.FirmwareUpdate)
      ledger.app.router.go '/'
    dialog.show()

  _refreshFirmwareStatus: ->
    ledger.fup.FirmwareUpdater.instance.getFirmwareUpdateAvailability ledger.app.wallet, no, no, (availability, error) =>
      return if error?
      @view.updateAvailabilityText.text do =>
        if availability.available
          _.str.sprintf t('wallet.settings.hardware.update_available'), ledger.fup.utils.versionToString(availability.currentVersion)
        else
          t('wallet.settings.hardware.no_update_available')
      @view.currentVersionText.text ledger.fup.utils.versionToString(availability.dongleVersion)
