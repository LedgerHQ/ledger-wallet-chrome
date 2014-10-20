require @ledger.imports, ->

  class Application

    constructor: ->
      @_navigationController = null
      @router = new Router(@)

    start: ->
      @router.go('/dashboard/index')


    navigate: (layoutName, viewController) ->
      if @_navigationController == null or @_navigationController.constructor.name != layoutName
        @_navigationController = new window[layoutName]()
        @_navigationController.push viewController
        @_navigationController.render $('body')

  @WALLET_LAYOUT = 'WalletNavigationController'
  @ONBOARDING_LAYOUT = 'OnboardingNavigationController'

  @ledger.application = new Application()
  @ledger.application.start()
