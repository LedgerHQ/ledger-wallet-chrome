require @ledger.imports, ->

  class Application extends ledger.common.application.BaseApplication

    chains:
      currentKey: ""

    Modes:
      Wallet: "Wallet"
      FirmwareUpdate: "FirmwareUpdate"
      Setup: "Setup"

    onStart: ->
      Api.init()
      ledger.errors.init()
      ledger.utils.Logger.updateGlobalLoggersLevel()
      @_listenAppEvents()
      addEventListener "message", Api.listener.bind(Api), false
      ledger.i18n.init =>
        ledger.preferences.common.init =>
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
        @donglesManager.pause()
        _.defer => @releaseWallet(no)
        ledger.utils.Logger.setGlobalLoggersPersistentLogsEnabled(off)
        ledger.utils.Logger.updateGlobalLoggersLevel()
      else
        @donglesManager.resume()
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
        ledger.tasks.TickerTask.instance.startIfNeccessary()

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

    onReconnectingDongle: () ->
      @_currentMode = ledger.app.Modes.Wallet

    onDongleIsUnlocked: (dongle) ->
      return unless @isInWalletMode()
      _.defer =>
        @emit 'dongle:unlocked', @dongle
        ledger.app.dongle.getCoinVersion().then ({P2PKH, P2SH, message}) =>
          l "Looking for #{P2PKH} #{P2SH}"

          networks = []
          for k, v of ledger.bitcoin.Networks
            if v.version.regular is P2PKH and v.version.P2SH is P2SH
              networks.push(v)
          if networks.length >1
            l "many chains available"
            _.defer =>
              ledger.app.dongle.getPublicAddress "44'/#{networks[0].bip44_coin_type}'/0'/0/0", (addr) =>
                address = ledger.crypto.SHA256.hashString addr.bitcoinAddress.toString(ASCII)
                ledger.app.chains.currentKey = address
                ledger.storage.global.chainSelector.get address, (result) =>
                  l result
                  if result[address]?
                    l "remember my choice found"
                    l result[address]
                    exists = false
                    if result[address] != 0
                      for k, v of ledger.bitcoin.Networks
                        if v.name == result[address].name
                          exists = k
                    if exists
                      @onChainChosen ledger.bitcoin.Networks[exists]
                    else
                      if networks[0].name != 'bitcoin'
                        ledger.app.router.go '/onboarding/device/chains/litecoin', {networks: JSON.stringify(networks)}
                      else
                        ledger.app.router.go '/onboarding/device/chains', {networks: JSON.stringify(networks)}
                  else
                    ###tmp = {}
                    tmp[address]= ledger.bitcoin.Networks.bitcoin
                    ledger.storage.global.chainSelector.set tmp, =>
                      ledger.app.onChainChosen(ledger.bitcoin.Networks.bitcoin)###
                    if networks[0].name != 'bitcoin'
                      ledger.app.router.go '/onboarding/device/chains/litecoin', {networks: JSON.stringify(networks)}
                    else
                      ledger.app.router.go '/onboarding/device/chains', {networks: JSON.stringify(networks)}
          else
            ledger.app.chains.currentKey = ""
            @onChainChosen networks[0]


    onChainChosen: (network) ->
      ledger.app.router.go '/onboarding/device/opening'
      _.defer =>
        l " on chain chosen"
        @emit 'wallet:initializing'
        ledger.config.network = network
        #ledger.config.network = ledger.bitcoin.Networks.testnet
        l ledger.config.network
        ledger.app.dongle.setCoinVersion(ledger.config.network.version.regular, ledger.config.network.version.P2SH)
        .then =>
          ledger.tasks.WalletOpenTask.instance.startIfNeccessary()
          ledger.tasks.WalletOpenTask.instance.onComplete (result, error) =>
            if error?
              # TODO: Handle wallet opening fatal error
              e "Raise", error
            ledger.tasks.FeesComputationTask.instance.startIfNeccessary()
            @_listenPreferencesEvents()
            @_listenCountervalueEvents(true)
            ledger.utils.Logger.updateGlobalLoggersLevel()
            @emit 'wallet:initialized'
            _.defer =>
              ledger.tasks.TransactionObserverTask.instance.startIfNeccessary()
              ledger.tasks.OperationsSynchronizationTask.instance.startIfNeccessary() unless result.operation_consumption

    onDongleIsDisconnected: (dongle) ->
      @emit 'dongle:disconnected'
      ledger.utils.Logger.setPrivateModeEnabled off
      return unless @isInWalletMode()
      @releaseWallet()

    onCommandFirmwareUpdate: -> @router.go '/' if @setExecutionMode(ledger.app.Modes.FirmwareUpdate)

    onCommandExportLogs: ->
      ledger.utils.Logger.downloadLogsWithLink()

    _listenAppEvents: () ->
      @on 'wallet:operations:sync:failed', =>

      @on 'wallet:operations:sync:done', =>

      @on 'wallet:operations:update wallet:operations:new', =>
        return unless @isInWalletMode()
        @_refreshBalance()


    _refreshBalance: _.debounce((=> Wallet.instance.retrieveAccountsBalances()), 500)

    _listenPreferencesEvents: ->
      ledger.preferences.instance.on 'btcUnit:changed language:changed locale:changed confirmationsCount:changed', => @scheduleReloadUi()
      ledger.preferences.instance.on 'logActive:changed', => ledger.utils.Logger.updateGlobalLoggersLevel()

    releaseWallet: (removeDongle = yes, reroute = yes) ->
      @emit 'dongle:disconnected' if reroute
      @_listenCountervalueEvents(false)
      _.defer =>
        ledger.api.SyncRestClient.reset()
        ledger.bitcoin.bitid.reset()
        ledger.preferences.close()
        ledger.utils.Logger.updateGlobalLoggersLevel()
        Wallet.releaseWallet()
        ledger.storage.closeStores()
        ledger.wallet.release(@dongle)
        ledger.tasks.Task.stopAllRunningTasks()
        ledger.tasks.Task.resetAllSingletonTasks()
        ledger.database.contexts.close()
        ledger.database.close()
        ledger.api.resetAuthentication()
        ledger.utils.Logger._secureWriter = null
        ledger.utils.Logger._secureReader = null
        if removeDongle and reroute
          @dongle?.disconnect()
          @dongle = null
        else if reroute
          @dongle?.lock()
        else
          ledger.tasks.TickerTask.instance.startIfNeccessary()
      ledger.dialogs.manager.dismissAll(no)
      @router.go '/onboarding/device/plug' if @isInWalletMode() and reroute

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
  @SPECS_LAYOUT = 'SpecNavigationController'

  ledger.database.Model.commitRelationship()

  @ledger.application = new Application()
  @ledger.app = @ledger.application
  @ledger.application.start()
