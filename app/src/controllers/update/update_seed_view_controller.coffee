class @UpdateSeedViewController extends UpdateViewController

  localizablePageSubtitle: "update.seed.security_card_qrcode"
  navigation:
    nextRoute: ""
    previousRoute: "/onboarding/device/plug"
    previousParams: {animateIntro: no}
  view:
    seedInput: "#seed_input"
    validCheck: "#valid_check"

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
    @getRequest().checkIfKeyCardSeedIsValid @view.seedInput.val()

  _listenEvents: ->
    # force focus
    @view.seedInput.on 'blur', => @view.seedInput.focus()
    _.defer => @view.seedInput.focus()
    # listen input
    @view.seedInput.on 'input', =>
      @parentViewController.updateNavigationItems()
      @_updateValidCheck()

  _updateValidCheck: ->
    if @getRequest().checkIfKeyCardSeedIsValid @view.seedInput.val() then @view.validCheck.show() else @view.validCheck.hide()