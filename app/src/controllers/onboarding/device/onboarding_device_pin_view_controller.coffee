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
        if success == yes
          ledger.app.router.go '/onboarding/device/opening'
        else if retryCount > 0
          ledger.app.router.go '/onboarding/device/wrongpin', {tries_left: retryCount}
        else
          ledger.app.router.go '/onboarding/device/frozen'

  openSupport: ->
    window.open t 'application.support_url'