class @UpdateSeedViewController extends UpdateViewController

  localizablePageSubtitle: "update.seed.security_card_qrcode"
  navigation:
    nextRoute: "/update/cardcheck"
    previousRoute: "/onboarding/device/plug"
    previousParams: {animateIntro: no}
  view:
    seedInput: "#seed_input"
    validCheck: "#valid_check"
    openScannerButton: "#open_scanner_button"

  onAfterRender: ->
    super
    @_listenEvents()
    @view.seedInput.val @params.seed if @params?.seed?
    @_updateValidCheck()

  navigatePrevious: ->
    ledger.app.setExecutionMode(ledger.app.Modes.Wallet)
    super

  navigateNext: ->
    @navigation.nextParams = {seed: @_seedInputvalue()}
    super

  shouldEnableNextButton: ->
    @_keychardValueIsValid @_seedInputvalue()

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
    if @_keychardValueIsValid @_seedInputvalue() then @view.validCheck.show() else @view.validCheck.hide()

  _seedInputvalue: ->
    _.str.trim @view.seedInput.val()