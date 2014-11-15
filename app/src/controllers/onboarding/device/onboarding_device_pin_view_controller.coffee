class @OnboardingDevicePinViewController extends @OnboardingViewController

  onAfterRender: ->
    super
    do @_insertPinCode

  _insertPinCode: ->
    @_pinCode = new ledger.pin_codes.PinCode()
    @_pinCode.insertIn(@select('div.greyed-container')[0])
    @_pinCode.setStealsFocus(yes)
    @_pinCode.on 'complete', (event, value)  ->
      ledger.application.devicesManager.devices()[0].lwCard.verifyPIN(value)

  openSupport: ->
    window.open t 'application.support_url'