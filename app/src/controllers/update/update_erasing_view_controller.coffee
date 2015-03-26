class @UpdateErasingViewController extends UpdateViewController

  localizableNextButton: "common.erase"
  localizablePageSubtitle: "update.erasing.erasure_confirmation"
  navigation:
    nextRoute: ""
    previousRoute: "/onboarding/device/plug"
    previousParams: {animateIntro: no}

  navigatePrevious: ->
    ledger.app.setExecutionMode(ledger.app.Modes.Wallet)
    super

  navigateNext: ->
    @getRequest().approveCurrentState()