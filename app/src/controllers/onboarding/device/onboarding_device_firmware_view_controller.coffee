class @OnboardingDeviceFirmwareViewController extends @OnboardingViewController

  view:
    notNowButton: "#not_now_button"

  updateNow: ->
    window.open("https://chrome.google.com/webstore/detail/ledger-manager/beimhnaefocolcplfimocfiaiefpkgbf")
    window.close()


  notNow: ->
    ledger.app.router.go '/onboarding/device/continue'