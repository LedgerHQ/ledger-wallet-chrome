class @OnboardingDevicePinViewController extends @OnboardingViewController

  onAfterRender: ->
    super
    @_pinCode = new ledger.pin_codes.PinCode()
    @_pinCode.insertIn(@select('div.greyed-container')[0])
    @_pinCode.focus()
    @_pinCode.on 'complete', (event, value)  ->
      ledger.application.devicesManager.devices()[0].lwCard.verifyPIN(value)
