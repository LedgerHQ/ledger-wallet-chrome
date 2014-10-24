class @OnboardingDevicePinViewController extends @ViewController

  onAfterRender: ->
    super
    @_pinCode = new ledger.pin_codes.PinCode()
    @_pinCode.insertIn(@select('div.greyed-container')[0])
    @_pinCode.focus()
