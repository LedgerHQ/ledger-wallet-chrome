class @UpdateIndexViewController extends @UpdateViewController

  navigation:
    nextRoute: ""
    previousRoute: "/onboarding/device/plug"
    previousParams: {animateIntro: no}
  localizablePageSubtitle: "update.index.important_notice"

  navigatePrevious: ->
    ledger.app.setExecutionMode(ledger.app.Modes.Wallet)
    super

  navigateNext: ->
    @getRequest().startUpdate()