require @ledger.imports, ->

  class Application extends ledger.base.application.BaseApplication

    onStart: ->
      @_listenAppEvents()
      @router.go('/')


    onConnectingDongle: (card) ->
      @emit 'dongle:connecting', card

    onDongleConnected: (wallet) ->
      @emit 'dongle:connected', @wallet
      ledger.tasks.TickerTask.instance.start()

    onDongleNeedsUnplug: (wallet) ->
      @emit 'dongle:unplugged', @wallet

    onDongleIsUnlocked: (wallet) ->
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

    onDongleIsDisconnected: (wallet) ->
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
