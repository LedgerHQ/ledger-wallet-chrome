class @UpdateUnlockingViewController extends UpdateViewController

  localizablePageSubtitle: "update.unlocking.pin_code"
  navigation:
    previousRoute: "/onboarding/device/plug"
    previousParams: {animateIntro: no}

  navigatePrevious: ->
    ledger.app.setExecutionMode(ledger.app.Modes.Wallet)
    super

  onAfterRender: ->
    super
    do @_insertPinCode

  _insertPinCode: ->
    @view.pinCode = new ledger.pin_codes.PinCode()
    @view.pinCode.insertIn(@select('div#pin_container')[0])
    @view.pinCode.setStealsFocus(yes)
    @view.pinCode.once 'complete', (event, value) =>
      @getRequest().unlockWithPinCode(value)

  resetWallet: ->
    ledger.app.router.go '/update/erasing'
