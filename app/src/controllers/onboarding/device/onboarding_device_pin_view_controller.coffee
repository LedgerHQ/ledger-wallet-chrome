class @OnboardingDevicePinViewController extends @OnboardingViewController

  onAfterRender: ->
    super
    do @_insertPinCode

  _insertPinCode: ->
    @view.pinCode = new ledger.pin_codes.PinCode()
    @view.pinCode.insertIn(@select('div#pin_container')[0])
    @view.pinCode.setStealsFocus(yes)
    @view.pinCode.once 'complete', (event, value) =>
      ledger.app.dongle.unlockWithPinCode value, (success, error) =>
        l error if error?
        if success
          firmware = ledger.app.dongle.getFirmwareInformation()
          if firmware.hasSubFirmwareSupport() and firmware.hasSetupFirmwareSupport()
            ledger.app.router.go '/onboarding/device/switch_firmware', pin: value, mode:'operation_and_open'
          else
            ledger.app.notifyDongleIsUnlocked()
            ledger.utils.Logger.setPrivateModeEnabled on
            ledger.app.router.go '/onboarding/device/opening'
        else if error.code == ledger.errors.WrongPinCode and error['retryCount'] > 0
          ledger.app.router.go '/onboarding/device/wrongpin', {tries_left: error['retryCount']}
        else if error.code == ledger.errors.NotSupportedDongle
          ledger.app.router.go '/onboarding/device/unsupported'
        else
          ledger.app.router.go '/onboarding/device/frozen'

  openSupport: ->
    window.open t 'application.support_url'