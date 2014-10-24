require @ledger.imports, ->

  class Application

    constructor: ->
      @_navigationController = null
      @devicesManager = new DevicesManager()
      @router = new Router(@)

    start: ->

      chrome.commands.onCommand.addListener (command) =>
        switch command
          when 'reload-page' then do @reloadUi
          when 'reload-application' then chrome.runtime.reload()


      @devicesManager.on 'plug', (event, device) ->
        l 'Plug'
        l device
      @devicesManager.on 'unplug', (event, device) ->
        l 'Unplug'
        l device
      @devicesManager.start()
      @router.go('/')

    navigate: (layoutName, viewController) ->
      @router.once 'routed', (event, data) =>
        oldUrl = if data.oldUrl? then data.oldUrl.parseAsUrl() else {hash: '', pathname: '', params: ''}
        newUrl = data.url.parseAsUrl()
        @currentUrl = data.url

        controller = null

        actionName = _.str.splice(newUrl.hash, 0, 1)
        onControllerRendered = () ->
          # Callback when the controller has been rendered
          @_navigationController.handleAction(actionName) if newUrl.hash.length > 0

        if @_navigationController == null or @_navigationController.constructor.name != layoutName
          @_navigationController = new window[layoutName]()
          controller = new viewController(newUrl.params())
          controller.on 'afterRender', onControllerRendered.bind(@)
          @_navigationController.push controller
          @_navigationController.render $('body')
        else
          if @_navigationController.topViewController().constructor.name == viewController.name and oldUrl.pathname == newUrl.pathname and newUrl.params == oldUrl.params # Check if only hash part of url change
            @_navigationController.handleAction(actionName)
          else
            controller = new viewController(newUrl.params())
            controller.on 'afterRender', onControllerRendered.bind(@)
            @_navigationController.push controller

    reloadUi: () ->
      $('link').each (_, link) ->
        if link.href?
          cleanHref = link.href
          cleanHref = cleanHref.replace(/\?[0-9]*/i, '')
          link.href = cleanHref + '?' + (new Date).getTime()
      @_navigationController.render $('body') if @_navigationController?


  @WALLET_LAYOUT = 'WalletNavigationController'
  @ONBOARDING_LAYOUT = 'OnboardingNavigationController'

  @ledger.application = new Application()
  @ledger.app = @ledger.application
  @ledger.application.start()
