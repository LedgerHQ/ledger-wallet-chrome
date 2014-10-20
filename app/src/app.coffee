require @ledger.imports, ->

  class Application

    constructor: ->
      @_navigationController = null
      @router = new Router(@)

    start: ->
      @router.go('/dashboard/index')

      do (@router) ->
        # Redirect every in-app link with our router
        $('body').delegate 'a', 'click', ->
          if @href? and @protocol == 'chrome-extension:'
            router.go @href
            return no
          yes


    navigate: (layoutName, viewController) ->
      if @_navigationController == null or @_navigationController.constructor.name != layoutName
        @_navigationController = new window[layoutName]()
        @_navigationController.push viewController
        @_navigationController.render $('body')

  @WALLET_LAYOUT = 'WalletNavigationController'
  @ONBOARDING_LAYOUT = 'OnboardingNavigationController'

  @ledger.application = new Application()
  @ledger.application.start()

  $(window).bind 'hashchange', ->
    l 'Salut'
    chrome.notifications.create 'test', {title: 'Hey', message: 'change'}, ->