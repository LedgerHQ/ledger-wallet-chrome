class @WalletSettingsIndexDialogViewController extends ledger.common.DialogViewController

  view:
    chain: '#chain'

  initialize: ->
    super
    @hardware = ledger.app.dongle.getIntFirmwareVersion()<0x30010101
    console.log("test is)", @hardware)
  onAfterRender: () ->
    super
    if !ledger.config.network.chain?
      @view.chain.css('opacity', '0.0')
      @view.chain.css('pointer-events', 'none')
  

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