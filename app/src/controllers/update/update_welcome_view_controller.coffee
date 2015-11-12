class @UpdateWelcomeViewController extends UpdateViewController

  localizablePageSubtitle: "update.welcome.ledger_wallet"
  navigation:
    nextRoute: ""
    previousRoute: "/onboarding/device/plug"
    previousParams: {animateIntro: no}

  navigatePrevious: ->
    ledger.app.setExecutionMode(ledger.app.Modes.Wallet)
    super

  navigateNext: ->
    @getRequest().startUpdate()