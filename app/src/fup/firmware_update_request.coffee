ledger.fup ?= {}

States =
  Undefined: 0
  Erasing: 1
  LoadingOldApplication: 2
  ReloadingBootloaderFromOs: 3
  LoadingBootloader: 4
  LoadingReloader: 5
  LoadingBootloaderReloader: 6
  LoadingOs: 7
  InitializingOs: 8
  Done: 9

Modes =
  Os: 0
  Bootloader: 1

Errors =
  InconsistentState: "InconsistentState"
  InvalidSeedSize: "Invalid seed size. The seed must have 32 characters"
  InvalidSeedFormat: "Invalid seed format. The seed must represent a hexadecimal value"
  GetVersionError: "GetVersionError"

ExchangeTimeout = 200

###
  FirmwareUpdateRequest performs dongle firmware updates. Once started it will listen the {WalletsManager} in order to catch
  connected dongles and update them. Only one instance of FirmwareUpdateRequest should be alive at the same time. (This is
  ensured by the {ledger.fup.FirmwareUpdater})

  @event plug Emitted when the user must plug its dongle in
  @event unplug Emitted when the user must unplug its dongle
  @event stateChanged Emitted when the current state has changed. The event holds a data formatted like this: {oldState: ..., newState: ...}
  @event setKeyCardSeed Emitted once the key card seed is provided
  @event needsUserApproval Emitted once the request needs a user input to continue
  @event erasureStep Emitted each time the erasure step is trying to reset the dongle. The event holds the number of remaining steps before erasing is done.
###
class ledger.fup.FirmwareUpdateRequest extends @EventEmitter

  @States: States

  @Modes: Modes

  @Errors: Errors

  @ExchangeTimeout: ExchangeTimeout

  constructor: (firmwareUpdater) ->
    @_fup = firmwareUpdater
    @_keyCardSeed = null
    @_completion = new CompletionClosure()
    @_currentState = States.Undefined
    @_isNeedingUserApproval = no
    @_lastMode = Modes.Os
    @_lastVersion = undefined
    @_isOsLoaded = no
    @_approvedStates = []
    @_stateCache = {} # This holds the state related data
    @_exchangeNeedsExtraTimeout = no
    @_isWaitForDongleSilent = no

  ###
    Stops all current tasks and listened events.
  ###
  cancel: () -> @_fup._cancelRequest(this)

  onComplete: (callback) -> @_completion.onComplete callback
  onProgress: (callback) -> @_onProgress = callback

  ###
    Approves the current request state and continue its execution.
  ###
  approveCurrentState: -> @_setIsNeedingUserApproval no

  isNeedingUserApproval: -> @_isNeedingUserApproval

  ###
    Gets the current dongle version
    @return [String] The current dongle version
  ###
  getDongleVersion: -> ledger.fup.utils.versionToString(@_dongleVersion)

  ###
    Gets the version to update
    @return [String] The target version
  ###
  getTargetVersion: -> ledger.fup.utils.versionToString(ledger.fup.versions.Nano.CurrentVersion.Os)


  ###
    Sets the key card seed used during the firmware update process. The seed must be a 32 characters string formatted as
    an hexadecimal value.

    @param [String] keyCardSeed A 32 characters string formatted as an hexadecimal value (i.e. '01294b7431234b5323f5588ce7d02703'
    @throw If the seed length is not 32 or if it is malformed
  ###
  setKeyCardSeed: (keyCardSeed) ->
    return if @_keyCardSeed?
    throw new Error(Errors.InvalidSeedSize) if not keyCardSeed? or keyCardSeed.length != 32
    seed = Try => new ByteString(keyCardSeed, HEX)
    throw new Error(Errors.InvalidSeedFormat) if seed.isFailure() or seed.getValue()?.length != 16
    @_keyCardSeed = seed.getValue()
    @emit "setKeyCardSeed"
    @_handleCurrentState()

  ###
    Gets the current state.

    @return [ledger.fup.FirmwareUpdateRequest.States] The current request state
  ###
  getCurrentState: -> @_currentState

  ###
    Checks if the current request has a key card seed or not.

    @return [Boolean] Yes if the key card seed has been setup
  ###
  hasKeyCardSeed: () -> if @_keyCardSeed? then yes else no

  _waitForConnectedDongle: (callback = undefined, silent = no) ->
    @_isWaitForDongleSilent = silent
    return @_connectionCompletion if @_connectionCompletion?
    completion = new CompletionClosure(callback)
    registerWallet = (wallet) =>
      @_lastMode = if wallet.isInBootloaderMode() then Modes.Bootloader else Modes.Os
      @_wallet = wallet
      wallet.once 'disconnected', =>
        @_setCurrentState(States.Undefined)
        @_wallet = null
        @_waitForConnectedDongle(null, @_isWaitForDongleSilent)
      @_handleCurrentState()
      completion.success(wallet)

    [wallet] = ledger.app.walletsManager.getConnectedWallets()
    try
      unless wallet?
        @_connectionCompletion = completion.readonly()
        delay = if !silent then 0 else 1000
        l "Wait for connection", silent
        setTimeout (=> @emit 'plug' unless @_wallet?), delay
        ledger.app.walletsManager.once 'connected', (e, wallet) =>
          @_connectionCompletion = null
          registerWallet(wallet)
      else
        registerWallet(wallet)
    catch er
      e er
    completion.readonly()


  _waitForDisconnectDongle: (callback = undefined, silent = no) ->
    return @_disconnectionCompletion if @_disconnectionCompletion?
    completion = new CompletionClosure(callback)
    if @_wallet?
      @emit 'unplug' unless silent
      @_disconnectionCompletion = completion.readonly()
      @_wallet.once 'disconnected', =>
        @_disconnectionCompletion = null
        @_wallet = null
        completion.success()
    else
      completion.success()
    completion.readonly()

  _waitForPowerCycle: (callback = undefined, silent = no) -> @_waitForDisconnectDongle(null, silent).then(=> @_waitForConnectedDongle(callback, silent).promise())

  _handleCurrentState: () ->
    # If there is no dongle wait for one
    (return @_waitForConnectedDongle()) unless @_wallet?

    # Otherwise handle the current by calling the right method depending on the last mode and the state
    if @_lastMode is Modes.Os
      switch @_currentState
        when States.Undefined then do @_processInitStageOs
        when States.ReloadingBootloaderFromOs then do @_processReloadBootloaderFromOs
        when States.InitializingOs then do @_processInitOs
        when States.Erasing then do @_processErasing
        else @_failure(Errors.InconsistentState)
    else
      switch @_currentState
        when States.Undefined then do @_processInitStageBootloader
        when States.LoadingOs then do @_processLoadOs
        when States.LoadingBootloader then do @_processLoadBootloader
        when States.LoadingBootloaderReloader then do @_processLoadBootloaderReloader

  _processInitStageOs: ->
    @_wallet.getState (state) =>
      if state isnt ledger.wallet.States.BLANK and state isnt ledger.wallet.States.FROZEN
        @_setCurrentState(States.Erasing)
        @_handleCurrentState()
      else
        l 'Time to update'
        @_fup.getFirmwareUpdateAvailability @_wallet, @_lastMode is Modes.Bootloader, no, (availability, error) =>
          # TODO: Handle error unable to get firmware version
          @_dongleVersion = availability.dongleVersion
          switch availability.result
            when ledger.fup.FirmwareUpdater.FirmwareAvailabilityResult.Overwrite
              if @_isOsLoaded
                @_setCurrentState(States.InitializingOs)
                @_handleCurrentState()
              else
                @_setCurrentState(States.ReloadingBootloaderFromOs)
                @_handleCurrentState()
            when ledger.fup.FirmwareUpdater.FirmwareAvailabilityResult.Update
              index = 0
              while index < ledger.fup.updates.OS_INIT.length and !ledger.fup.utils.compareVersions(@_dongleVersion, ledger.fup.updates.OS_INIT[index][0]).eq()
                index += 1
              if index isnt ledger.fup.updates.OS_INIT.length
                @_processLoadingScript(ledger.fup.updates.OS_INIT[index][1], States.LoadingOldApplication, true)
                .then =>
                  @_setCurrentState(States.ReloadingBootloaderFromOs)
                  @_handleCurrentState()
                .fail => @_failure() # TODO: Handle error properly
              else
                @_setCurrentState(States.ReloadingBootloaderFromOs)
                @_handleCurrentState()
            else return @_failure() # TODO: Handle error properly

  _processErasing: ->
    @_waitForUserApproval('erasure')
    .then =>
      unless @_stateCache.pincode?
        getRandomChar = -> "0123456789".charAt(_.random(10))
        @_stateCache.pincode = getRandomChar() + getRandomChar()
      pincode = @_stateCache.pincode
      @_wallet.unlockWithPinCode pincode, (isUnlocked, error) =>
        @emit "erasureStep", if error?.retryCount? then error.retryCount else 3
        @_waitForPowerCycle()
      return
    .fail ->
      # TODO: PROPER ERROR
      e "ERROR IN ERASURE"
    .done()

  _processInitOs: ->
    l 'Time to init OS'
    currentInitScript = _(ledger.fup.updates.OS_INIT).last()[1]
    moddedInitScript = []
    for i in [0...currentInitScript.length]
      moddedInitScript.push currentInitScript[i]
      if i is currentInitScript.length - 2
        moddedInitScript.push "D026000011" + "04" + @_keyCardSeed.toString(HEX)
    @_processLoadingScript moddedInitScript, States.InitializingOs, yes
    .then =>
      @_setCurrentState(States.Done)
      @_isOsLoaded = no
      @_onComplete.success()
    .fail =>
      # TODO: Handle error during init OS

  _processReloadBootloaderFromOs: ->
    l 'Time to reload bootloader from os'
    @_waitForUserApproval('reloadbootloader')
    .then =>
      @_removeUserApproval('reloadbootloader')
      l 'The party may begin'
      index = 0
      while index < ledger.fup.updates.BL_RELOADER.length and !ledger.fup.utils.compareVersions(@_dongleVersion, ledger.fup.updates.BL_RELOADER[index][0]).eq()
        index += 1
      l 'load BL_RELOADER', index
      if index is ledger.fup.updates.BL_RELOADER.length
        e "This firmware is not supported"
        # TODO: Handle This firmware is not supported
        return
      l 'Process loading'
      @_isWaitForDongleSilent = yes
      @_processLoadingScript ledger.fup.updates.BL_RELOADER[index][1], States.ReloadingBootloaderFromOs
      .then =>
        @_waitForPowerCycle(null, yes)
      .fail (e) =>
        l 'Failure', e
        # TODO: If e is 0x6985 -> Error loading reloader. If the dongle is set up, make sure to erase the seed before updating the firmware
        # TODO: If e is 0x6faa -> Error loading reloader. You might not have the right personalization on your card - make sure you're not using a pre-release or test card
        # TODO: Else -> Error loading with code
        @_waitForDisconnectDongle()



  _processInitStageBootloader: ->
    @_lastVersion = null
    @_wallet.getRawFirmwareVersion yes, yes, (version, error) =>
      return @_failure() if error? # TODO: Handle error unable to get firmware version
      @_lastVersion = version
      if ledger.fup.utils.compareVersions(version, ledger.fup.versions.Nano.CurrentVersion.Bootloader).eq()
        @_setCurrentState(States.LoadingOs)
        @_handleCurrentState()
      else if ledger.fup.utils.compareVersions(version, ledger.fup.versions.Nano.CurrentVersion.Reloader).eq()
        @_setCurrentState(States.LoadingBootloader)
        @_handleCurrentState()
      else
        SEND_RACE_BL = (1 << 16) + (3 << 8) + (11)
        @_exchangeNeedsExtraTimeout = result[1] < SEND_RACE_BL
        @_setCurrentState(States.LoadingBootloaderReloader)
        @_handleCurrentState()

  _processLoadOs: ->
    l 'Load OS now'
    @_isOsLoaded = no
    @_findOriginalKey(ledger.fup.updates.OS_LOADER).then (offset) =>
      @_isWaitForDongleSilent = yes
      @_processLoadingScript(ledger.fup.updates.OS_LOADER[offset], States.LoadingOs).then (result) =>
        @_isOsLoaded = yes
        @_setCurrentState(States.Undefined)
        _.delay (=> @_waitForPowerCycle(null, yes)), 200
      .fail (e) =>
        @_isWaitForDongleSilent = no
        @_setCurrentState(States.Undefined)
        @_failure() # TODO: Handle properly
    .fail (e) =>
      @_isWaitForDongleSilent = no
      @_setCurrentState(States.Undefined)

  _processLoadBootloader: ->
    l 'Load Bootloader now'

  _processLoadBootloaderReloader: ->
    l 'Load Bootloader reloader now'

  _getVersion: (forceBl, callback) -> @_wallet.getRawFirmwareVersion(@_lastMode is Modes.Bootloader, forceBl, callback)

  _compareVersion: (v1, v2) ->

  _failure: (reason) ->
    @_waitForPowerCycle()

  _attemptToFailDonglePinCode: (pincode) ->
    deferred = Q.defer()
    @_wallet.unlockWithPinCode pincode, (isUnlocked, error) =>
      if isUnlocked or error.code isnt ledger.errors.WrongPinCode
        @emit "erasureStep", 3
        @_waitForPowerCycle().then -> deferred.reject()
      else
        l 'Here I am', arguments
        @emit "erasureStep", error.retryCount
        l 'Wait for'
        @_waitForPowerCycle()
        .then =>
          l 'Power cycled'
          @_wallet.getState (state) =>
            deferred.resolve(state is ledger.wallet.States.BLANK or state is ledger.wallet.States.FROZEN)
    deferred.promise

  _setCurrentState: (newState) ->
    oldState = @_currentState
    @_currentState = newState
    @emit 'stateChanged', {oldState, newState}

  _setIsNeedingUserApproval: (value) ->
    if @_isNeedingUserApproval isnt value
      @_isNeedingUserApproval = value
      if @_isNeedingUserApproval is true
        @emit 'needsUserApproval'
        @_deferredApproval = Q.defer()
      else
        defferedApproval = @_deferredApproval
        @_deferredApproval = null
        defferedApproval.resolve()
    return

  _cancelApproval: ->
    if @_isNeedingUserApproval
      @_isNeedingUserApproval = no
      defferedApproval = @_deferredApproval
      @_deferredApproval = null
      defferedApproval.reject("cancelled")

  _waitForUserApproval: (approvalName) ->
    if _.contains(@_approvedStates, approvalName)
      deferred = Q.defer()
      deferred.resolve()
      deferred.promise
    else
      @_setIsNeedingUserApproval  yes
      @_deferredApproval.promise.then => @_approvedStates.push approvalName

  _removeUserApproval: (approvalName) ->
    @_approvedStates = _(@_approvedStates).without(approvalName)
    return

  _processLoadingScript: (adpus, state, ignoreSW, offset = 0) ->
    completion = new CompletionClosure()
    @_doProcessLoadingScript(adpus, state, ignoreSW, offset).then(-> completion.success()).fail((ex) -> completion.failure(ex))
    completion.readonly()

  _doProcessLoadingScript: (adpus, state, ignoreSW, offset) ->
    l '_doProcessLoadingScript', offset, adpus.length
    @_notifyProgress(state, offset, adpus.length)
    if offset >= adpus.length
      @_exchangeNeedsExtraTimeout = no
      return
    try
      l 'Writing', adpus[offset]
      @_wallet._lwCard.dongle.card.exchange_async(new ByteString(adpus[offset], HEX))
      .then =>
        l 'After exchange'
        if ignoreSW or @_wallet._lwCard.dongle.card.SW == 0x9000
          l 'Exchange OK'
          if @_exchangeNeedsExtraTimeout
            deferred = Q.defer()
            _.delay (=> deferred.resolve(@_doProcessLoadingScript(adpus, state, ignoreSW, offset + 1))), ExchangeTimeout
            deferred.promise()
          else
            @_doProcessLoadingScript(adpus, state, ignoreSW, offset + 1)
        else
          l 'Exchange Not OK'
          @_exchangeNeedsExtraTimeout = no
          # TODO: Place Logger here
          l 'Unexpected status', @_wallet._lwCard.dongle.card.SW
          throw new Error('Unexpected status ' + @_wallet._lwCard.dongle.card.SW)
      .fail (ex) =>
        return @_doProcessLoadingScript(adpus, state, ignoreSW, offset + 1) if offset is adpus.length - 1
        @_exchangeNeedsExtraTimeout = no
        throw new Error("ADPU sending failed " + ex)
    catch ex
      e ex

  _findOriginalKey: (loadingArray, offset = 0) ->
    throw new Error("Key not found") if offset >= loadingArray.length
    @_wallet._lwCard.dongle.card.exchange_async(new ByteString(loadingArray[offset][0], HEX)).then (result) =>
      if @_wallet._lwCard.dongle.card.SW == 0x9000
        offset
      else
        @_findOriginalKey(loadingArray, offset + 1)
    .fail (er) =>
      throw new Error("Communication Error")

  _notifyProgress: (state, offset, total) -> _.defer => @_onProgress?(state, offset, total)