class @OnboardingViewController extends ledger.common.ViewController

  view:
    continueButton: '#continue_button'
  navigation:
    continueUrl: undefined

  onAfterRender: ->
    super
    do @unbindWindow
    do @bindWindow

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
    swapped_bip39: @params.swapped_bip39

  _finalNavigationBackParams: ->
    _.extend(@_defaultNavigationBackParams(), @navigationBackParams())

  _finalNavigationContinueParams: ->
    _.extend(@_defaultNavigationContinueParams(), @navigationContinueParams())

  navigateRoot: ->
    dialog = new CommonDialogsConfirmationDialogViewController()
    dialog.setMessageLocalizableKey 'onboarding.management.cancel_wallet_configuration'
    dialog.positiveLocalizableKey = 'common.no'
    dialog.negativeLocalizableKey = 'common.yes'
    dialog.once 'click:negative', =>
      ledger.app.router.go @params.rootUrl
    dialog.show()

  navigateBack: ->
    ledger.app.router.go @params.back, @_finalNavigationBackParams()

  navigateContinue: (url, params) ->
    url = undefined unless _.isFunction(url?.parseAsUrl)
    params = _.extend(@_defaultNavigationContinueParams(), params) if params?
    ledger.app.router.go (url || @navigation.continueUrl), (params || @_finalNavigationContinueParams())

  unbindWindow: ->
    $(window).unbind 'keyup', null

  bindWindow: ->
    if @view.continueButton? and @view.continueButton.length == 1
      $(window).on 'keyup', (e) =>
        if (e.keyCode == 13)
          if (!@view.continueButton.hasClass 'disabled')
            @view.continueButton.click()
