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

  _defaultNavigationBackParams: ->
    {}

  _defaultNavigationContinueParams: ->
    wallet_mode: @params.wallet_mode
    rootUrl: @params.rootUrl
    back: @representativeUrl()
    step: parseInt(@params.step) + 1

  _finalNavigationBackParams: ->
    _.extend(@_defaultNavigationBackParams(), @navigationBackParams())

  _finalNavigationContinueParams: ->
    _.extend(@_defaultNavigationContinueParams(), @navigationContinueParams())

  navigateRoot: ->
    dialog = new CommonDialogsConfirmationDialogViewController()
    dialog.setMessageLocalizableKey 'onboarding.management.cancel_wallet_configuration'
    dialog.once 'click:negative', =>
      ledger.app.router.go @params.rootUrl
    dialog.show()

  navigateBack: ->
    ledger.app.router.go @params.back, @_finalNavigationBackParams()

  navigateContinue: ->
    ledger.app.router.go @navigation.continueUrl, @_finalNavigationContinueParams()

  unbindWindow: ->
    $(window).unbind 'keyup', null

  bindWindow: ->
    if @view.continueButton? and @view.continueButton.length == 1
      $(window).on 'keyup', (e) =>
        if (e.keyCode == 13)
          if (!@view.continueButton.hasClass 'disabled')
            @view.continueButton.click()
