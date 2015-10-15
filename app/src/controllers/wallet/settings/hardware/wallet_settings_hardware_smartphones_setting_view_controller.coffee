class @WalletSettingsHardwareSmartphonesSettingViewController extends WalletSettingsSettingViewController

  renderSelector: "#smartphones_table_container"

  initialize: ->
    super
    @_smartphonesGroups = []

  pairSmartphone: ->
    dialog = new WalletPairingIndexDialogViewController()
    dialog.show()
    dialog.getDialog().once 'dismiss', =>
      @rerender()

  removeSmartphoneGroup: (params) ->
    secureScreens = @_smartphonesGroups[params.index]
    dialog = new CommonDialogsConfirmationDialogViewController()
    dialog.setMessageLocalizableKey 'common.errors.deleting_this_paired_smartphone'
    dialog.positiveLocalizableKey = 'common.no'
    dialog.negativeLocalizableKey = 'common.yes'
    dialog.once 'click:negative', =>
      ledger.m2fa.PairedSecureScreen.removePairedSecureScreensFromSyncedStore secureScreens, =>
        @rerender()
    dialog.show()

  render: (selector) ->
    return unless ledger.app.dongle?
    # get out if firmware does not support mobile second factor
    unless ledger.app.dongle.getFirmwareInformation().hasSecureScreen2FASupport()
      _.defer => @emit 'afterRender'
      return
    ledger.m2fa.PairedSecureScreen.getAllGroupedByUuidFromSyncedStore (smartphonesGroups, error) =>
      return if error? or not smartphonesGroups?
      @_smartphonesGroups = _.sortBy _.values(_.omit(smartphonesGroups, undefined)), (item) -> item[0]?.name
      super selector