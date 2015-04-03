class @WalletSettingsHardwareDialogViewController extends @DialogViewController

  view:
    smartphonesTableContainer: "#smartphones_table_container"
    currentVersionText: "#current_version_text"
    updateAvailabilityText: "#update_availability_text"

  smartphonesGroups: []

  onAfterRender: ->
    super
    @_refreshSmartphonesList()
    @_refreshFirmwareStatus()

  flashFirmware: ->
    dialog = new CommonDialogsConfirmationDialogViewController()
    dialog.setMessageLocalizableKey 'common.errors.going_to_firmware_update'
    dialog.once 'click:negative', =>
      ledger.app.setExecutionMode(ledger.app.Modes.FirmwareUpdate)
      ledger.app.router.go '/'
    dialog.show()

  pairSmartphone: ->
    dialog = new WalletPairingIndexDialogViewController()
    dialog.show()
    dialog.getDialog().once 'dismiss', =>
      @_refreshSmartphonesList()

  removeSmartphoneGroup: (params) ->
    secureScreens = @smartphonesGroups[params.index]
    dialog = new CommonDialogsConfirmationDialogViewController()
    dialog.setMessageLocalizableKey 'common.errors.deleting_this_paired_smartphone'
    dialog.once 'click:negative', =>
      ledger.m2fa.PairedSecureScreen.removePairedSecureScreensFromSyncedStore secureScreens, =>
        @_refreshSmartphonesList()
    dialog.show()

  _refreshSmartphonesList: ->
    ledger.m2fa.PairedSecureScreen.getAllGroupedByUuidFromSyncedStore (smartphonesGroups, error) =>
      return if error? or not smartphonesGroups?
      smartphonesGroups = _.sortBy _.values(_.omit(smartphonesGroups, undefined)), (item) -> item[0]?.name
      # render partial
      render "wallet/settings/_hardware_smartphones_list", smartphonesGroups: smartphonesGroups, (html) =>
        return if not html?
        # retain smartphones
        @smartphonesGroups = smartphonesGroups
        # clear node
        @view.smartphonesTableContainer.empty()
        @view.smartphonesTableContainer.append html

  _refreshFirmwareStatus: ->
    ledger.fup.FirmwareUpdater.instance.getFirmwareUpdateAvailability ledger.app.wallet, no, no, (availability, error) =>
      return if error?
      @view.updateAvailabilityText.text do =>
        if availability.available
          _.str.sprintf t('wallet.settings.hardware.update_available'), ledger.fup.utils.versionToString(availability.currentVersion)
        else
          t('wallet.settings.hardware.no_update_available')
      @view.currentVersionText.text ledger.fup.utils.versionToString(availability.dongleVersion)
