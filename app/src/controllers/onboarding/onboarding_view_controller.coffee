class @OnboardingViewController extends ledger.common.ViewController

  view:
    continueButton: '#continue_button'

  onAfterRender: ->
    super
    do @unbindWindow
    do @bindWindow

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

  unbindWindow: ->
    $(window).unbind 'keyup', null

  bindWindow: ->
    if @view.continueButton? and @view.continueButton.length == 1
      $(window).on 'keyup', (e) =>
        if(e.keyCode == 13)
          if(!@view.continueButton.hasClass 'disabled')
            @view.continueButton.click()
