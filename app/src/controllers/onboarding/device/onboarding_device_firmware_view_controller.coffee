class @OnboardingDeviceFirmwareViewController extends @OnboardingViewController

  view:
    notNowButton: "#not_now_button"

  updateNow: ->
    window.close()


  notNow: ->
    ledger.app.router.go '/onboarding/device/continue'