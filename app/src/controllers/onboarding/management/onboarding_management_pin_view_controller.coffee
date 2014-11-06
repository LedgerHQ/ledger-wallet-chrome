class @OnboardingManagementPinViewController extends @ViewController

  onAfterRender: ->
    super
    do @_insertPinCodes

  _insertPinCodes: ->
    @_autoPinCode = new ledger.pin_codes.PinCode()
    @_autoPinCode.insertAfter(@select('#choice-auto > label')[0])
    @_autoPinCode.setProtected no
    @_autoPinCode.setReadonly yes
    @_autoPinCode.setValue 1234
    @_manualPinCode = new ledger.pin_codes.PinCode()
    @_manualPinCode.insertAfter(@select('#choice-manual > label')[0])
