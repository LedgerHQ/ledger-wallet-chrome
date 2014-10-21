require @ledger.imports, ->

  class Application

    constructor: ->
      @_navigationController = null
      @devicesManager = new DevicesManager()
      @router = new Router(@)

    start: ->
      @devicesManager.on 'plug', (event, device) ->
        l 'Plug'
        l device
      @devicesManager.on 'unplug', (event, device) ->
        l 'Unplug'
        l device
      @devicesManager.start()
      @router.go('/dashboard/index')

    navigate: (layoutName, viewController) ->
      @router.once 'routed', (event, data) =>
        oldUrl = if data.oldUrl? then data.oldUrl.parseAsUrl() else {hash: '', pathname: '', params: ''}
        newUrl = data.url.parseAsUrl()
        @currentUrl = data.url

        controller = null

        actionName = _.str.splice(newUrl.hash, 0, 1)
        onControllerRendered = () ->
          # Callback when the controller has been rendered
           controller.handleAction(actionName) if newUrl.hash.length > 0

        if @_navigationController == null or @_navigationController.constructor.name != layoutName
          @_navigationController = new window[layoutName]()
          controller = new viewController
          controller.on 'afterRender', onControllerRendered.bind(@)
          @_navigationController.push new viewController()
          @_navigationController.render $('body')
        else
          if @_navigationController.topViewController().constructor.name == viewController.name and oldUrl.pathname == newUrl.pathname and newUrl.params == oldUrl.params # Check if only hash part of url change
            @_navigationController.topViewController().handleAction(actionName)
          else
            controller = new viewController
            controller.on 'afterRender', onControllerRendered.bind(@)
            @_navigationController.push controller


  @WALLET_LAYOUT = 'WalletNavigationController'
  @ONBOARDING_LAYOUT = 'OnboardingNavigationController'

  @ledger.application = new Application()
  @ledger.application.start()
