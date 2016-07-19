class @OnboardingViewController extends ledger.common.ViewController

  view:
    continueButton: '#continue_button'
  navigation:
    continueUrl: undefined
  bumpsStepCount: true

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
    step: parseInt(@params.step) + if @_canBumpNextViewControllerStepCount() then 1 else 0
    swapped_bip39: @params.swapped_bip39

  _finalNavigationBackParams: ->
    _.extend(@_defaultNavigationBackParams(), @navigationBackParams())

  _finalNavigationContinueParams: ->
    _.extend(@_defaultNavigationContinueParams(), @navigationContinueParams())

  _canBumpNextViewControllerStepCount: ->
    words = _.str.words(_.str.underscored(@identifier()), "_")
    return words.length >= 2 && words[1] == "management" && @bumpsStepCount

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

  openHelpCenter: ->
    window.open t 'application.support_url'

  bindWindow: ->
    if @view.continueButton? and @view.continueButton.length == 1
      $(window).on 'keyup', (e) =>
        if (e.keyCode == 13)
          if (!@view.continueButton.hasClass 'disabled')
            @view.continueButton.click()
