require @ledger.imports, ->

  class Application extends ledger.base.application.BaseApplication

    onStart: ->
      @_listenAppEvents()
      @_listenWalletEvents()
      @router.go('/')

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



  @WALLET_LAYOUT = 'WalletNavigationController'
  @ONBOARDING_LAYOUT = 'OnboardingNavigationController'

  Model.commitRelationship()

  @ledger.application = new Application()
  @ledger.app = @ledger.application
  @ledger.application.start()
