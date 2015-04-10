class @OnboardingViewController extends @ViewController

  view:
    continueButton: '#continue_button'
    doc: 'document'

  onAfterRender: ->
    super
    do @bindContinue

  navigation:
    continueUrl: undefined

  navigationBackParams: ->
    undefined

  navigationContinueParams: ->
    undefined

  navigateRoot: ->
    dialog = new CommonDialogsConfirmationDialogViewController()
    dialog.setMessageLocalizableKey 'onboarding.management.cancel_wallet_configuration'
    dialog.once 'click:negative', =>
      ledger.app.router.go @params.rootUrl
    dialog.show()

  navigateBack: ->
    ledger.app.router.go @params.back, @navigationBackParams()

  navigateContinue: ->
    ledger.app.router.go @navigation.continueUrl, @navigationContinueParams()

  bindContinue: ->
    l("Binding ENTER keypress")
    if @view.continueButton? and @view.continueButton.length == 1
      l("Found button")
      window.on 'keyup', (e) ->
        l(e.keyCode)
        # if (@value.indexOf('.') != -1) and e.keyCode == 110
        #   e.preventDefault
        #   return no
        # @view.continueButton.click()
    else
      l("Button not found")