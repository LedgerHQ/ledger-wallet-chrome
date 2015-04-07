require @ledger.imports, ->

  class Application extends ledger.base.application.BaseApplication

    Modes:
      Wallet: "Wallet"
      FirmwareUpdate: "FirmwareUpdate"

    onStart: ->
      Api.init()
      @_listenAppEvents()
      addEventListener "message", Api.listener.bind(Api), false
      @setExecutionMode(@Modes.Wallet)
      @router.go '/'

    ###
      Sets the execution mode of the application. In Wallet mode, the application handles the wallets state by starting services,
      emitting specific events. This mode is the normal one, it allows access to accounts, balances...
      In FirmwareUpdate mode, the management of dongles is delegated to an instance of {ledger.fup.FirmwareUpdateRequest}.

      Once the execution mode changes, the application will render the corresponding {NavigationController}.

    ###
    setExecutionMode: (newMode) ->
      throw "Unknown execution mode: #{newMode}. Available modes are ledger.app.Wallet or ledger.app.FirmwareUpdate." if _(_.values(@Modes)).find((m) -> m is newMode).length is 0
      return if newMode is @_currentMode
      @_currentMode = newMode
      if @isInFirmwareUpdateMode()
        @_releaseWallet(no)
      return

    ###
      Checks if the application is in wallet mode.

      @return [Boolean] True if the application is in wallet mode, false otherwise
    ###
    isInWalletMode: -> @_currentMode is @Modes.Wallet

    ###
      Checks if the application is in firmware update mode.

      @return [Boolean] True if the application is in firmware update mode, false otherwise.
    ###
    isInFirmwareUpdateMode: -> @_currentMode is @Modes.FirmwareUpdate

    onConnectingDongle: (device) ->
      @emit 'dongle:connecting', device if @isInWalletMode() and !device.isInBootloaderMode

    onDongleConnected: (dongle) ->
      @performDongleAttestation() if @isInWalletMode() and not dongle.isInBootloaderMode()

    onDongleCertificationDone: (dongle, isCertified) ->
      return unless @isInWalletMode()
      if isCertified
        @emit 'dongle:connected', @dongle
      else
        @emit 'dongle:forged', @dongle

    onDongleIsInBootloaderMode: (dongle) ->
      @setExecutionMode(ledger.app.Modes.FirmwareUpdate)
      ledger.app.router.go '/'

    onDongleNeedsUnplug: (dongle) ->
      @emit 'dongle:unplugged', @dongle if @isInWalletMode()

    onDongleIsUnlocked: (dongle) ->
      return unless @isInWalletMode()
      @emit 'dongle:unlocked', @dongle
      @emit 'wallet:initializing'
      ledger.wallet.initialize @dongle, =>
        ledger.db.init =>
          ledger.db.contexts.open()
          Wallet.initializeWallet =>
            @emit 'wallet:initialized'
            _.defer =>
              Wallet.instance.retrieveAccountsBalances()
              ledger.tasks.TransactionObserverTask.instance.start()
              ledger.tasks.OperationsSynchronizationTask.instance.start()
              ledger.tasks.OperationsConsumptionTask.instance.start()

    onDongleIsDisconnected: (dongle) ->
      @emit 'dongle:disconnected'
      return unless @isInWalletMode()
      @_releaseWallet()

    onCommandFirmwareUpdate: ->
      @setExecutionMode(ledger.app.Modes.FirmwareUpdate)
      @router.go '/'

    _listenAppEvents: () ->

      @on 'wallet:operations:sync:failed', =>
        return unless @isInWalletMode()
        _.delay =>
          ledger.tasks.OperationsConsumptionTask.instance.startIfNeccessary() if @dongle?
          ledger.tasks.OperationsSynchronizationTask.instance.startIfNeccessary() if @dongle?
        , 500

      @on 'wallet:operations:sync:done', =>

      @on 'wallet:operations:update wallet:operations:new', =>
        return unless @isInWalletMode()
        Wallet.instance.retrieveAccountsBalances()

    _releaseWallet: (removeDongle = yes) ->
      @emit 'dongle:disconnected'
      Wallet.releaseWallet()
      ledger.wallet.release(@dongle)
      ledger.tasks.Task.stopAllRunningTasks()
      ledger.tasks.Task.resetAllSingletonTasks()
      ledger.db.contexts.close()
      ledger.db.close()
      @dongle = null if removeDongle
      ledger.dialogs.manager.dismissAll(no)
      @router.go '/onboarding/device/plug' if @isInWalletMode()

  @WALLET_LAYOUT = 'WalletNavigationController'
  @ONBOARDING_LAYOUT = 'OnboardingNavigationController'
  @UPDATE_LAYOUT = 'UpdateNavigationController'

  Model.commitRelationship()

  @ledger.application = new Application()
  @ledger.app = @ledger.application
  @ledger.application.start()
