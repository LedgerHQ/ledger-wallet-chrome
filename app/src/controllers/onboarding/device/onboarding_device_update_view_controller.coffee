class @OnboardingDeviceUpdateViewController extends @OnboardingViewController

  view:
    notNowButton: "#not_now_button"

  updateNow: ->
    ledger.app.setExecutionMode(ledger.app.Modes.FirmwareUpdate)
    ledger.app.router.go '/'

  notNow: ->
    ledger.app.dongle.getState (state) =>
      if state == ledger.dongle.States.LOCKED
        ledger.app.router.go '/onboarding/device/pin'
      else
        ledger.app.router.go '/onboarding/management/welcome'

  onAfterRender: ->
    super
    if ledger.app.dongle.getStringFirmwareVersion() is "1.0.0"
      @view.notNowButton.hide()