class @OnboardingViewController extends @ViewController

  navigation:
    continueUrl: undefined

  navigationBackParams: ->
    undefined

  navigationContinueParams: ->
    undefined

  navigateBack: ->
    ledger.app.router.go @params.back, @navigationBackParams()

  navigateContinue: ->
    ledger.app.router.go @navigation.continueUrl, @navigationContinueParams()