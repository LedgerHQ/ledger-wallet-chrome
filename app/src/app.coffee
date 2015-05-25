require @ledger.imports, ->

  class Application extends ledger.common.application.BaseApplication

    Modes:
      Wallet: "Wallet"
      FirmwareUpdate: "FirmwareUpdate"

    onStart: ->
      Api.init()
      ledger.errors.init()
      ledger.utils.Logger.updateGlobalLoggersLevel()
      @_listenAppEvents()
      addEventListener "message", Api.listener.bind(Api), false
      ledger.i18n.init =>
        ledger.preferences.defaults.init =>
          @router.go('/') if @setExecutionMode(@Modes.Wallet)

    ###
      Sets the execution mode of the application. In Wallet mode, the application handles the wallets state by starting services,
      emitting specific events. This mode is the normal one, it allows access to accounts, balances...
      In FirmwareUpdate mode, the management of dongles is delegated to an instance of {ledger.fup.FirmwareUpdateRequest}.

      Once the execution mode changes, the application will render the corresponding {NavigationController}.

    ###
    setExecutionMode: (newMode) ->
      throw "Unknown execution mode: #{newMode}. Available modes are ledger.app.Wallet or ledger.app.FirmwareUpdate." if _(_.values(@Modes)).find((m) -> m is newMode).length is 0
      return false if newMode is @_currentMode
      @_currentMode = newMode
      if @isInFirmwareUpdateMode()
        @_releaseWallet(no)
        ledger.utils.Logger.setGlobalLoggersPersistentLogsEnabled(off)
        ledger.utils.Logger.updateGlobalLoggersLevel()
      else
        ledger.utils.Logger.setGlobalLoggersPersistentLogsEnabled(on)
        ledger.utils.Logger.updateGlobalLoggersLevel()
        @connectDongle(ledger.app.dongle) if ledger.app.dongle?
      return true

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
      if @isInWalletMode() and not dongle.isInBootloaderMode()
        @performDongleAttestation()
        ledger.tasks.TickerTask.instance.start()

    onDongleCertificationDone: (dongle, error) ->
      return unless @isInWalletMode()
      if not error?
        @emit 'dongle:connected', @dongle
      else if error.code is ledger.errors.DongleNotCertified
        @emit 'dongle:forged', @dongle
      else if error.code is ledger.errors.CommunicationError
        @emit 'dongle:communication_error', @dongle

    onDongleIsInBootloaderMode: (dongle) -> ledger.app.router.go '/' if @setExecutionMode(ledger.app.Modes.FirmwareUpdate)

    onDongleNeedsUnplug: (dongle) ->
      @emit 'dongle:unplugged', @dongle if @isInWalletMode()

    onDongleIsUnlocked: (dongle) ->
      return unless @isInWalletMode()
      @emit 'dongle:unlocked', @dongle
      @emit 'wallet:initializing'
      ledger.tasks.WalletOpenTask.instance.startIfNeccessary()
      ledger.tasks.WalletOpenTask.instance.onComplete (__, error) =>
        if error?
          # TODO: Handle wallet opening fatal error
        else
          @_listenPreferencesEvents()
          @_listenCountervalueEvents(true)
          ledger.utils.Logger.updateGlobalLoggersLevel()
          @emit 'wallet:initialized'
          _.defer =>
            Wallet.instance.retrieveAccountsBalances()
            ledger.tasks.TransactionObserverTask.instance.start()
            ledger.tasks.OperationsSynchronizationTask.instance.start()
            ledger.tasks.OperationsConsumptionTask.instance.start()

    onDongleIsDisconnected: (dongle) ->
      @emit 'dongle:disconnected'
      ledger.utils.Logger.setPrivateModeEnabled off
      return unless @isInWalletMode()
      @_releaseWallet()

    onCommandFirmwareUpdate: -> @router.go '/' if @setExecutionMode(ledger.app.Modes.FirmwareUpdate)

    onCommandExportLogs: ->
      ledger.utils.Logger.downloadLogsWithLink()

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

    _listenPreferencesEvents: ->
      ledger.preferences.instance.on 'btcUnit:changed language:changed locale:changed confirmationsCount:changed', => @scheduleReloadUi()
      ledger.preferences.instance.on 'logActive:changed', => ledger.utils.Logger.updateGlobalLoggersLevel()

    _releaseWallet: (removeDongle = yes) ->
      @emit 'dongle:disconnected'
      @_listenCountervalueEvents(false)
      ledger.preferences.close()
      ledger.utils.Logger.updateGlobalLoggersLevel()
      Wallet.releaseWallet()
      ledger.storage.closeStores()
      ledger.wallet.release(@dongle)
      ledger.tasks.Task.stopAllRunningTasks()
      ledger.tasks.Task.resetAllSingletonTasks()
      ledger.database.contexts.close()
      ledger.database.close()
      ledger.utils.Logger._secureWriter = null
      ledger.utils.Logger._secureReader = null
      if removeDongle
        @dongle = null
      else
        @dongle?.lock()
      ledger.dialogs.manager.dismissAll(no)
      @router.go '/onboarding/device/plug' if @isInWalletMode()

    _listenCountervalueEvents: (listen) ->
      if !listen
        @_countervalueObserver?.disconnect()
        @_countervalueObserver = undefined
        @_listenedCountervalueNodes = undefined
        @_reprocessCountervalueNodesCallback = undefined
        ledger.preferences.instance?.off 'currency:changed', @_reprocessCountervalueNodesCallback
        ledger.preferences.instance?.off 'locale:changed', @_reprocessCountervalueNodesCallback
        ledger.tasks.TickerTask.instance?.off 'updated', @_reprocessCountervalueNodesCallback
        return

      recomputeCountervalue = (node) =>
        qNode = $(node)
        text = ''
        currency = ledger.preferences.instance.getCurrency()
        if ledger.formatters.symbolIsFirst()
          text += currency + ' '
        satoshis = qNode.attr('data-countervalue')
        sign = satoshis.charAt(0)
        sign = '' if (not sign? or (sign != '+' && sign != '-'))
        satoshis = _.str.replace(satoshis, sign, '')
        text += sign
        text += ledger.converters.satoshiToCurrency(satoshis, currency)
        if !ledger.formatters.symbolIsFirst()
          text += ' ' + currency
        qNode.text(text)

      handleChanges = (summaries) =>
        for summary in summaries
          for node in summary.added
            # add from watchlist
            @_listenedCountervalueNodes.push node
            recomputeCountervalue(node)
          for node in summary.valueChanged
            recomputeCountervalue(node)
          for node in summary.removed
            # remove from watchlist
            index = @_listenedCountervalueNodes.indexOf(node)
            @_listenedCountervalueNodes.splice(index, 1) if index != -1

      @_reprocessCountervalueNodesCallback = =>
        for node in @_listenedCountervalueNodes
          recomputeCountervalue(node)

      # listen app events
      ledger.preferences.instance.on 'currency:changed', @_reprocessCountervalueNodesCallback
      ledger.preferences.instance.on 'locale:changed', @_reprocessCountervalueNodesCallback
      ledger.tasks.TickerTask.instance.on 'updated', @_reprocessCountervalueNodesCallback

      # listen countervalue nodes
      @_listenedCountervalueNodes = []
      @_countervalueObserver = new MutationSummary(
        callback: handleChanges
        rootNode: $('body').get(0)
        observeOwnChanges: false
        oldPreviousSibling: false
        queries: [{ attribute: 'data-countervalue' }]
      )

  @WALLET_LAYOUT = 'WalletNavigationController'
  @ONBOARDING_LAYOUT = 'OnboardingNavigationController'
  @UPDATE_LAYOUT = 'UpdateNavigationController'
  @COINKITE_LAYOUT = 'AppsCoinkiteNavigationController'

  ledger.database.Model.commitRelationship()

  @ledger.application = new Application()
  @ledger.app = @ledger.application
  @ledger.application.start()
