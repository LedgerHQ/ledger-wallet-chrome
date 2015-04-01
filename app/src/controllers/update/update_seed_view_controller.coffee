class @UpdateSeedViewController extends UpdateViewController

  localizablePageSubtitle: "update.seed.security_card_qrcode"
  navigation:
    nextRoute: ""
    previousRoute: "/onboarding/device/plug"
    previousParams: {animateIntro: no}
  view:
    seedInput: "#seed_input"
    validCheck: "#valid_check"
    openScannerButton: "#open_scanner_button"

  onAfterRender: ->
    super
    @_listenEvents()
    @_updateValidCheck()

  navigatePrevious: ->
    ledger.app.setExecutionMode(ledger.app.Modes.Wallet)
    super

  navigateNext: ->
    @getRequest().setKeyCardSeed(@view.seedInput.val())

  shouldEnableNextButton: ->
    @_keychardValueIsValid @view.seedInput.val()

  _keychardValueIsValid: (value) =>
    return @getRequest().checkIfKeyCardSeedIsValid value

  _listenEvents: ->
    # force focus
    @view.seedInput.on 'blur', => @view.seedInput.focus()
    _.defer => @view.seedInput.focus()
    # listen input
    @view.seedInput.on 'input', =>
      @parentViewController.updateNavigationItems()
      @_updateValidCheck()
    @view.openScannerButton.on 'click', =>
      dialog = new CommonDialogsQrcodeDialogViewController
      dialog.qrcodeCheckBlock = (data) =>
        return @_keychardValueIsValid data
      dialog.once 'qrcode', (event, data) =>
        @view.seedInput.val data
        @parentViewController.updateNavigationItems()
        @_updateValidCheck()
      dialog.show()

  _updateValidCheck: ->
    if @_keychardValueIsValid @view.seedInput.val() then @view.validCheck.show() else @view.validCheck.hide()