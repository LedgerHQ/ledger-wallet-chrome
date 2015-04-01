class @OnboardingDeviceUpdateViewController extends @OnboardingViewController

  updateNow: ->
    ledger.app.setExecutionMode(ledger.app.Modes.FirmwareUpdate)
    ledger.app.router.go '/'

  notNow: ->
    ledger.app.dongle.getState (state) =>
      if state == ledger.dongle.States.LOCKED
        ledger.app.router.go '/onboarding/device/pin'
      else
        ledger.app.router.go '/onboarding/management/welcome'