class @OnboardingDeviceUnsupportedViewController extends @OnboardingViewController

  updateNow: ->
    ledger.app.setExecutionMode(ledger.app.Modes.FirmwareUpdate)
    ledger.app.router.go '/'