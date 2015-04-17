class @OnboardingDeviceFailedViewController extends @OnboardingViewController

  updateNow: ->
    ledger.app.setExecutionMode(ledger.app.Modes.FirmwareUpdate)
    ledger.app.router.go '/'