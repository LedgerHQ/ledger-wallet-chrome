class @UpdateIndexViewController extends @UpdateViewController

  navigation:
    nextRoute: "/update/seed"
    previousRoute: "/onboarding/device/plug"
    previousParams: {animateIntro: no}
  localizablePageSubtitle: "update.index.important_notice"

  navigatePrevious: ->
    ledger.app.setExecutionMode(ledger.app.Modes.Wallet)
    super