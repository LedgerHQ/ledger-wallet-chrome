class @OnboardingDevicePinViewController extends @OnboardingViewController

  view:
    currentAction: "#current_action"
  timer: null

  onAfterRender: ->
    super
    @view.spinner = ledger.spinners.createLargeSpinner(@select('div.greyed-container')[0])
    ledger.app.dongle.unlockWithPinCode '0000', (success, error) =>
      l error if error?
      if success
        firmware = ledger.app.dongle.getFirmwareInformation()
        if firmware.hasSubFirmwareSupport() and !firmware.hasOperationFirmwareSupport()
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