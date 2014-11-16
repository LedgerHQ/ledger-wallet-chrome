class @OnboardingDevicePinViewController extends @OnboardingViewController

  onAfterRender: ->
    super
    do @_insertPinCode

  _insertPinCode: ->
    @view.pinCode = new ledger.pin_codes.PinCode()
    @view.pinCode.insertIn(@select('div.greyed-container')[0])
    @view.pinCode.setStealsFocus(yes)
    @view.pinCode.once 'complete', (event, value) =>
      ledger.app.wallet.unlockWithPinCode value, (success, retryCount) =>
        l success
        l retryCount

  openSupport: ->
    window.open t 'application.support_url'