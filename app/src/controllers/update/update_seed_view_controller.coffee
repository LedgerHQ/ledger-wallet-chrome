class @UpdateSeedViewController extends UpdateViewController

  localizablePageSubtitle: "update.seed.security_card_qrcode"
  navigation:
    nextRoute: "/update/cardcheck"
    previousRoute: "/update/welcome"
    previousParams: {animateIntro: no}
  view:
    seedInput: "#seed_input"
    validCheck: "#valid_check"
    openScannerButton: "#open_scanner_button"


  render: ->
    super
    if @getRequest().getDongleFirmware().hasSubFirmwareSupport()
      @navigation.previousRoute = "/update/updating"

  onAfterRender: ->
    super
    @_listenEvents()
    @view.seedInput.val @params.seed if @params?.seed?
    @_updateValidCheck()

  navigateNext: ->
    @navigation.nextParams =
      seed: @_seedInputvalue()
      redirect_to_updating: @params?.redirect_to_updating
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
    @view.seedInput.on 'input propertychange', =>
      @parentViewController.updateNavigationItems()
      @_updateValidCheck()
      @_updateInputSize()
    @view.openScannerButton.on 'click', =>
      dialog = new CommonDialogsQrcodeDialogViewController
      dialog.qrcodeCheckBlock = (data) =>
        return @_keychardValueIsValid data
      dialog.once 'qrcode', (event, data) =>
        @view.seedInput.val data
        @parentViewController.updateNavigationItems()
        @_updateValidCheck()
        @_updateInputSize()
      dialog.show()

  _updateValidCheck: ->
    if @_keychardValueIsValid @_seedInputvalue() then @view.validCheck.show() else @view.validCheck.hide()

  _updateInputSize: ->
    if @_seedInputvalue().length > 32
      @view.seedInput.addClass 'large'
    else
      @view.seedInput.removeClass 'large'

  _seedInputvalue: ->
    _.str.trim @view.seedInput.val()