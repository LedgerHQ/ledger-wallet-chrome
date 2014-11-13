class @OnboardingViewController extends @ViewController

  navigation:
    continueUrl: undefined

  navigationBackParams: ->
    undefined

  navigationContinueParams: ->
    undefined

  navigateRoot: ->
    dialog = new CommonDialogsConfirmationDialogViewController()
    dialog.setAbstractLocalizableKey 'onboarding.management.cancel_wallet_configuration'
    dialog.setMessageLocalizableKey 'onboarding.management.wallet_not_affected'
    dialog.once 'click:negative', =>
      ledger.app.router.go @params.rootUrl
    dialog.show()

  navigateBack: ->
    ledger.app.router.go @params.back, @navigationBackParams()

  navigateContinue: ->
    ledger.app.router.go @navigation.continueUrl, @navigationContinueParams()