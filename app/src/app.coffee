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
      chrome.commands.onCommand.addListener (command) =>
        switch command
          when 'reload-page' then do @reloadUi
          when 'reload-application' then chrome.runtime.reload()

      @_listenWalletEvents()

      @devicesManager.start()
      @router.go('/')

      ledger.storage.openStores('merguez')

      ### MODELS/COLLECTIONS LEGACY TESTS DO NOT REMOVE
      account = Account.findOrCreate 1, {name: 'Toto', balance: 16, operations: [{_id: 1, name: 'opTest'}]}
      account.get (result) =>
       account.getOperations (operations) =>
         operations.iterator (it) =>
            operations.insert {_id: it.length(), name: 'Auto'}

            operations.toArray (array) => l array

            account.getOperation (operation) =>
              unless operation?
                account.set 'operation', new Operation({_id: 'abcdefghij'})
              l operation
              account.set '_id', result._id + 1
              account.set 'name', result.name + '1'
              account.set 'balance', result.balance * 2
              account.save () =>
                account = Account.findOrCreate 1, {name: 'Toto', balance: 16}
                account.get (result) =>
                  l result
                  toRemove = Account.create(name: 'ToRemove').save =>
                    toRemove.remove =>
                      Account.create({name: 'Test'}).save () =>
                        ledger.collections.accounts.toArray (a) =>
                          l a
                        ledger.collections.accounts.each (object) =>
                          l object
      ###

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
          @emit 'dongle:disconnected'
          @wallet = null
        wallet.once 'unplugged', =>
          @emit 'dongle:unplugged', @wallet
        wallet.once 'state:unlocked', =>
          @emit 'dongle:unlocked', @wallet
          @emit 'wallet:initializing'
          ledger.wallet.initialize @wallet, =>
            @emit 'wallet:initialized'
        @emit 'dongle:connected', @wallet



  @WALLET_LAYOUT = 'WalletNavigationController'
  @ONBOARDING_LAYOUT = 'OnboardingNavigationController'

  @ledger.application = new Application()
  @ledger.app = @ledger.application
  @ledger.application.start()
