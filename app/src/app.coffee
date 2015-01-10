require @ledger.imports, ->

  class Application extends EventEmitter

    _navigationControllerSelector: -> $('#controllers_container')

    constructor: ->
      @_navigationController = null
      @devicesManager = new DevicesManager()
      @walletsManager = new WalletsManager(this)
      @router = new Router(@)
      ledger.dialogs.manager.initialize($('#dialogs_container'))

    start: ->
      configureApplication @

      @_listenWalletEvents()
      @_listenClickEvents()
      @_listenAppEvents()
      @devicesManager.start()
      @router.go('/')

    reload: () ->
      @devicesManager.stop()
      chrome.runtime.reload()

    navigate: (layoutName, viewController) ->
      @router.once 'routed', (event, data) =>
        oldUrl = if @_lastUrl? then @_lastUrl.parseAsUrl() else {hash: '', pathname: '', params: -> ''}
        newUrl = data.url.parseAsUrl()
        @_lastUrl = data.url
        @currentUrl = data.url
        controller = null

        ## Create action name and action parameters
        [actionName, parameters] = ledger.url.parseAction(newUrl.hash)

        onControllerRendered = () ->
          # Callback when the controller has been rendered
          @handleAction(actionName, parameters) if newUrl.hash.length > 0

        if @_navigationController == null or @_navigationController.constructor.name != layoutName
          @_navigationController = new window[layoutName]()
          controller = new viewController(newUrl.params(), data.url)
          controller.on 'afterRender', onControllerRendered.bind(@)
          @_navigationController.push controller
          @_navigationController.render @_navigationControllerSelector()
        else
          if @_navigationController.topViewController().constructor.name == viewController.name and oldUrl.pathname == newUrl.pathname and _.isEqual(newUrl.params(), oldUrl.params()) # Check if only hash part of url change
           @handleAction(actionName, parameters)
          else
            controller = new viewController(newUrl.params(), data.url)
            controller.on 'afterRender', onControllerRendered.bind(@)
            @_navigationController.push controller

    reloadUi: () ->
      $('link').each (_, link) ->
        if link.href? && link.href.length > 0
          cleanHref = link.href
          cleanHref = cleanHref.replace(/\?[0-9]*/i, '')
          link.href = cleanHref + '?' + (new Date).getTime()
      @_navigationController.render @_navigationControllerSelector() if @_navigationController?

    handleAction: (actionName, params) ->
      handled = no
      if ledger.dialogs.manager.displayedDialog()?
        handled = ledger.dialogs.manager.displayedDialog().handleAction actionName, params
      handled = @_navigationController.handleAction(actionName, params) unless handled
      handled

    _listenWalletEvents: () ->
      # Wallet management & wallet events re-dispatching
      @walletsManager.on 'connecting', (event, card) =>
        @emit 'dongle:connecting', card
      @walletsManager.on 'connected', (event, wallet) =>
        @wallet = wallet
        wallet.once 'disconnected', =>
          _.defer =>
            try
              @emit 'dongle:disconnected'
              Wallet.releaseWallet()
              ledger.wallet.release(wallet)
              ledger.tasks.Task.stopAllRunningTasks()
              ledger.tasks.Task.resetAllSingletonTasks()
              ledger.db.contexts.close()
              ledger.db.close()
              @wallet = null
              ledger.dialogs.manager.dismissAll(no)
              @router.go '/onboarding/device/plug'
            catch er
              e er
        wallet.once 'unplugged', =>
          @emit 'dongle:unplugged', @wallet
        wallet.once 'state:unlocked', =>
          @emit 'dongle:unlocked', @wallet
          @emit 'wallet:initializing'
          ledger.wallet.initialize @wallet, =>
            ledger.db.init =>
              ledger.db.contexts.open()
              Wallet.initializeWallet =>
                @emit 'wallet:initialized'
                _.defer =>
                  Wallet.instance.retrieveAccountsBalances()
                  ledger.tasks.TransactionObserverTask.instance.start()
                  ledger.tasks.OperationsSynchronizationTask.instance.start()
                  ledger.tasks.OperationsConsumptionTask.instance.start()
        @emit 'dongle:connected', @wallet

    _listenAppEvents: () ->

      @on 'wallet:operations:sync:failed', =>
        l 'Failed'
        _.delay =>
          ledger.tasks.OperationsConsumptionTask.instance.startIfNeccessary() if @wallet?
          ledger.tasks.OperationsSynchronizationTask.instance.startIfNeccessary() if @wallet?
        , 500

      @on 'wallet:operations:sync:done', =>

      @on 'wallet:operations:update wallet:operations:new', =>
        Wallet.instance.retrieveAccountsBalances()

    _listenClickEvents: () ->
      self = @
      # Redirect every in-app link with our router
      $('body').delegate 'a', 'click', (e) ->
        if @href? and @protocol == 'chrome-extension:'
          url = null
          if  _.str.startsWith(@pathname, '/views/') and self.currentUrl?
            url = ledger.url.createRelativeUrlWithFragmentedUrl(self.currentUrl, @href)
          else
            url = @pathname + @search + @hash
          self.router.go url
          return no
        yes

      $('body').delegate '[data-href]', 'click', (e) ->
        href = $(this).attr('data-href')
        if href? and href.length > 0
          parser = href.parseAsUrl()
          if  _.str.startsWith(parser.pathname, '/views/') and self.currentUrl?
            url = ledger.url.createRelativeUrlWithFragmentedUrl(self.currentUrl, href)
          else
            url = parser.pathname + parser.search + parser.hash
          self.router.go url
          return no
        yes


  @WALLET_LAYOUT = 'WalletNavigationController'
  @ONBOARDING_LAYOUT = 'OnboardingNavigationController'

  Model.commitRelationship()

  @ledger.application = new Application()
  @ledger.app = @ledger.application
  @ledger.application.start()
