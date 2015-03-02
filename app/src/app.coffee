require @ledger.imports, ->

  Modes =
    Wallet: "Wallet"
    FirmwareUpdate: "FirmwareUpdate"

  class Application extends ledger.base.application.BaseApplication

    Modes: Modes

    onStart: ->
      @_listenAppEvents()
      @setExecutionMode(Modes.Wallet)

    ###
      Sets the execution mode of the application. In Wallet mode, the application handles the wallets state by starting services,
      emitting specific events. This mode is the normal one, it allows access to accounts, balances...
      In FirmwareUpdate mode, the management of dongles is delegated to an instance of {ledger.fup.FirmwareUpdateRequest}.

      Once the execution mode changes, the application will render the corresponding {NavigationController}.

    ###
    setExecutionMode: (newMode) ->
      throw "Unknown execution mode: #{newMode}. Available modes are ledger.app.Wallet or ledger.app.FirmwareUpdate." if _(_.values(Modes)).find((m) -> m is newMode).length is 0
      return if newMode is @_currentMode
      @_currentMode = newMode
      if @isInWalletMode()
        @router.go '/'
      else if @isInFirmwareUpdateMode()
        @_releaseWallet()

      return

    ###
      Checks if the application is in wallet mode.

      @return [Boolean] True if the application is in wallet mode, false otherwise
    ###
    isInWalletMode: -> @_currentMode is Modes.Wallet

    ###
      Checks if the application is in firmware update mode.

      @return [Boolean] True if the application is in firmware update mode, false otherwise.
    ###
    isInFirmwareUpdateMode: -> @_currentMode is Modes.FirmwareUpdate

    onConnectingDongle: (card) ->
      @emit 'dongle:connecting', card if @isInWalletMode()

    onDongleConnected: (wallet) ->
      @emit 'dongle:connected', @wallet if @isInWalletMode()

    onDongleNeedsUnplug: (wallet) ->
      @emit 'dongle:unplugged', @wallet if @isInWalletMode()

    onDongleIsUnlocked: (wallet) ->
      return unless @isInWalletMode()
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
      return unless @isInWalletMode()
      @_releaseWallet()

    _listenAppEvents: () ->

      @on 'wallet:operations:sync:failed', =>
        return unless @isInWalletMode()
        _.delay =>
          ledger.tasks.OperationsConsumptionTask.instance.startIfNeccessary() if @wallet?
          ledger.tasks.OperationsSynchronizationTask.instance.startIfNeccessary() if @wallet?
        , 500

      @on 'wallet:operations:sync:done', =>

      @on 'wallet:operations:update wallet:operations:new', =>
        return unless @isInWalletMode()
        Wallet.instance.retrieveAccountsBalances()

    _releaseWallet: ->
      @emit 'dongle:disconnected'
      Wallet.releaseWallet()
      ledger.wallet.release(@wallet)
      ledger.tasks.Task.stopAllRunningTasks()
      ledger.tasks.Task.resetAllSingletonTasks()
      ledger.db.contexts.close()
      ledger.db.close()
      @wallet = null
      ledger.dialogs.manager.dismissAll(no)
      @router.go '/onboarding/device/plug' if @isInWalletMode()

  @WALLET_LAYOUT = 'WalletNavigationController'
  @ONBOARDING_LAYOUT = 'OnboardingNavigationController'

  Model.commitRelationship()

  @ledger.application = new Application()
  @ledger.app = @ledger.application
  @ledger.application.start()
