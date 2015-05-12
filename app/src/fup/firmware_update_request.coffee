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
  UnableToRetrieveVersion: ledger.errors.UnableToRetrieveVersion
  InvalidSeedSize: ledger.errors.InvalidSeedSize
  InvalidSeedFormat: ledger.errors.InvalidSeedFormat
  InconsistentState: ledger.errors.InconsistentState
  FailedToInitOs: ledger.errors.FailedToInitOs
  CommunicationError: ledger.errors.CommunicationError
  UnsupportedFirmware: ledger.errors.UnsupportedFirmware
  ErrorDongleMayHaveASeed: ledger.errors.ErrorDongleMayHaveASeed
  ErrorDueToCardPersonalization: ledger.errors.ErrorDueToCardPersonalization
  HigherVersion: ledger.errors.HigherVersion

ExchangeTimeout = 200

###
  FirmwareUpdateRequest performs dongle firmware updates. Once started it will listen the {DonglesManager} in order to catch
  connected dongles and update them. Only one instance of FirmwareUpdateRequest should be alive at the same time. (This is
  ensured by the {ledger.fup.FirmwareUpdater})

  @event plug Emitted when the user must plug its dongle in
  @event unplug Emitted when the user must unplug its dongle
  @event stateChanged Emitted when the current state has changed. The event holds a data formatted like this: {oldState: ..., newState: ...}
  @event setKeyCardSeed Emitted once the key card seed is provided
  @event needsUserApproval Emitted once the request needs a user input to continue
  @event erasureStep Emitted each time the erasure step is trying to reset the dongle. The event holds the number of remaining steps before erasing is done.
  @event error Emitted once an error is throw. The event holds a data formatted like this: {cause: ...}
###
class ledger.fup.FirmwareUpdateRequest extends @EventEmitter

  @States: States

  @Modes: Modes

  @Errors: Errors

  @ExchangeTimeout: ExchangeTimeout

  constructor: (firmwareUpdater) ->
    @_id = _.uniqueId("fup")
    @_fup = firmwareUpdater
    @_keyCardSeed = null
    @_currentState = States.Undefined
    @_isNeedingUserApproval = no
    @_lastMode = Modes.Os
    @_lastVersion = undefined
    @_isOsLoaded = no
    @_approvedStates = []
    @_stateCache = {} # This holds the state related data
    @_exchangeNeedsExtraTimeout = no
    @_isWaitForDongleSilent = no
    @_isCancelled = no
    @_eventHandler = []
    @_logger = ledger.utils.Logger.getLoggerByTag('FirmwareUpdateRequest')

  ###
    Stops all current tasks and listened events.
  ###
  cancel: () ->
    @off()
    _(@_eventHandler).each ([object, event, handler]) -> object?.off?(event, handler)
    @_onProgress = null
    @_isCancelled = yes
    @_fup._cancelRequest(this)

  onProgress: (callback) -> @_onProgress = callback

  hasGrantedErasurePermission: -> _.contains(@_approvedStates, "erasure")

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
    return if @_keyCardSeed? and @_currentState isnt States.Undefined
    throw new Error(Errors.InvalidSeedSize) if not keyCardSeed? or keyCardSeed.length != 32
    seed = Try => new ByteString(keyCardSeed, HEX)
    throw new Error(Errors.InvalidSeedFormat) if seed.isFailure() or seed.getValue()?.length != 16
    @_keyCardSeed = seed.getValue()
    @emit "setKeyCardSeed"
    @_handleCurrentState()

  ###
    Checks if a given keycard seed is valid or not. The seed must be a 32 characters string formatted as
    an hexadecimal value.

    @param [String] keyCardSeed A 32 characters string formatted as an hexadecimal value (i.e. '01294b7431234b5323f5588ce7d02703'
  ###
  checkIfKeyCardSeedIsValid: (keyCardSeed) -> (Try => @_keyCardSeedToByteString(keyCardSeed)).isSuccess()

  _keyCardSeedToByteString: (keyCardSeed, safe = no) ->
    throw new Error(Errors.InvalidSeedSize) if not keyCardSeed? or keyCardSeed.length != 32
    seed = Try => new ByteString(keyCardSeed, HEX)
    throw new Error(Errors.InvalidSeedFormat) if seed.isFailure() or seed.getValue()?.length != 16
    seed


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
    d = ledger.defer(callback)
    registerDongle = (dongle) =>
      @_lastMode = if dongle.isInBootloaderMode() then Modes.Bootloader else Modes.Os
      @_dongle = dongle
      handler =  =>
        @_setCurrentState(States.Undefined)
        @_dongle = null
        @_waitForConnectedDongle(null, @_isWaitForDongleSilent)
      dongle.once 'state:disconnected', handler
      @_eventHandler.push [dongle, 'state:disconnected', handler]
      @_handleCurrentState()
      d.resolve(dongle)
    [dongle] = ledger.app.donglesManager.getConnectedDongles()
    try
      unless dongle?
        @_connectionCompletion = d.promise
        delay = if !silent then 0 else 1000
        setTimeout (=> @emit 'plug' unless @_dongle?), delay
        handler = (e, dongle) =>
          @_connectionCompletion = null
          registerDongle(dongle)
        ledger.app.donglesManager.once 'connected', handler
        @_eventHandler.push [ledger.app.donglesManager, 'connected', handler]
      else
        registerDongle(dongle)
    catch er
      e er
    d.promise

  _waitForDisconnectDongle: (callback = undefined, silent = no) ->
    return @_disconnectionCompletion if @_disconnectionCompletion?
    d = ledger.defer(callback)
    if @_dongle?
      @emit 'unplug' unless silent
      @_disconnectionCompletion = d.promise
      @_dongle.once 'state:disconnected', =>
        @_disconnectionCompletion = null
        @_dongle = null
        d.resolve()
    else
      d.resolve()
    d.promise

  _waitForPowerCycle: (callback = undefined, silent = no) -> @_waitForDisconnectDongle(null, silent).then(=> @_waitForConnectedDongle(callback, silent))

  _handleCurrentState: () ->
    # If there is no dongle wait for one
    return @_waitForConnectedDongle() unless @_dongle?
    @_logger.info("Handle current state", lastMode: @_lastMode, currentState: @_currentState)

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
        else @_failure(Errors.InconsistentState)

  _processInitStageOs: ->
    @_logger.info("Process init stage OS")
    @_dongle.getState (state) =>
      if state isnt ledger.dongle.States.BLANK and state isnt ledger.dongle.States.FROZEN
        @_setCurrentState(States.Erasing)
        @_handleCurrentState()
      else
        @_fup.getFirmwareUpdateAvailability @_dongle, @_lastMode is Modes.Bootloader, no, (availability, error) =>
          return if error?
          @_dongleVersion = availability.dongleVersion
          switch availability.result
            when ledger.fup.FirmwareUpdater.FirmwareAvailabilityResult.Overwrite
              if @_isOsLoaded
                @_setCurrentState(States.InitializingOs)
                @_handleCurrentState()
              else
                @_dongle.isBetaCertified (__, error) =>
                  @_setCurrentState(if error? and ledger.fup.versions.Nano.CurrentVersion.Overwrite is false then States.InitializingOs else States.ReloadingBootloaderFromOs)
                  @_handleCurrentState()
                return
            when ledger.fup.FirmwareUpdater.FirmwareAvailabilityResult.Update, ledger.fup.FirmwareUpdater.FirmwareAvailabilityResult.Higher
              index = 0
              while index < ledger.fup.updates.OS_INIT.length and !ledger.fup.utils.compareVersions(@_dongleVersion, ledger.fup.updates.OS_INIT[index][0]).eq()
                index += 1
              if index isnt ledger.fup.updates.OS_INIT.length
                @_processLoadingScript(ledger.fup.updates.OS_INIT[index][1], States.LoadingOldApplication, true)
                .then =>
                  @_setCurrentState(States.ReloadingBootloaderFromOs)
                  @_handleCurrentState()
                .fail => @_failure(Errors.CommunicationError)
              else
                @_setCurrentState(States.ReloadingBootloaderFromOs)
                @_handleCurrentState()
            else return @_failure(Errors.HigherVersion)
          return

  _processErasing: ->
    @_waitForUserApproval('erasure')
    .then =>
      unless @_stateCache.pincode?
        getRandomChar = -> "0123456789".charAt(_.random(10))
        @_stateCache.pincode = getRandomChar() + getRandomChar()
      pincode = @_stateCache.pincode
      @_dongle.unlockWithPinCode pincode, (isUnlocked, error) =>
        @emit "erasureStep", if error?.retryCount? then error.retryCount else 3
        @_waitForPowerCycle()
      return
    .fail =>
      @_failure(Errors.CommunicationError)
    .done()

  _processInitOs: ->
    index = 0
    while index < ledger.fup.updates.OS_INIT.length and !ledger.fup.utils.compareVersions(ledger.fup.versions.Nano.CurrentVersion.Os, ledger.fup.updates.OS_INIT[index][0]).eq()
      index += 1
    currentInitScript = if ledger.fup.updates.OS_INIT[index]? then ledger.fup.updates.OS_INIT[index][1] else _(ledger.fup.updates.OS_INIT).last()[1]
    moddedInitScript = []
    for i in [0...currentInitScript.length]
      moddedInitScript.push currentInitScript[i]
      if i is currentInitScript.length - 2
        moddedInitScript.push "D026000011" + "04" + @_keyCardSeed.toString(HEX)
    @_processLoadingScript moddedInitScript, States.InitializingOs, yes
    .then =>
      @_success()
      @_isOsLoaded = no
    .fail =>
      @_failure(Errors.FailedToInitOs)

  _processReloadBootloaderFromOs: ->
    @_removeUserApproval('erasure')
    @_waitForUserApproval('reloadbootloader')
    .then =>
      @_removeUserApproval('reloadbootloader')
      index = 0
      while index < ledger.fup.updates.BL_RELOADER.length and !ledger.fup.utils.compareVersions(@_dongleVersion, ledger.fup.updates.BL_RELOADER[index][0]).eq()
        index += 1
      if index is ledger.fup.updates.BL_RELOADER.length
        @_failure(Errors.UnsupportedFirmware)
        return
      @_isWaitForDongleSilent = yes
      @_processLoadingScript ledger.fup.updates.BL_RELOADER[index][1], States.ReloadingBootloaderFromOs
      .then =>
        @_waitForPowerCycle(null, yes)
      .fail (e) =>
        switch @_getCard().SW
          when 0x6985
            @_processInitOs()
            return
          when 0x6faa then @_failure(Errors.ErrorDueToCardPersonalization)
          else @_failure(Errors.CommunicationError)
        @_waitForDisconnectDongle()
    .fail (err) ->
      console.error(err)

  _processInitStageBootloader: ->
    @_lastVersion = null
    @_dongle.getRawFirmwareVersion yes, yes, (version, error) =>
      return @_failure(Errors.UnableToRetrieveVersion) if error?
      @_lastVersion = version
      if ledger.fup.utils.compareVersions(version, ledger.fup.versions.Nano.CurrentVersion.Bootloader).eq()
        @_setCurrentState(States.LoadingOs)
        @_handleCurrentState()
      else if ledger.fup.utils.compareVersions(version, ledger.fup.versions.Nano.CurrentVersion.Reloader).eq()
        @_setCurrentState(States.LoadingBootloader)
        @_handleCurrentState()
      else
        SEND_RACE_BL = (1 << 16) + (3 << 8) + (11)
        @_exchangeNeedsExtraTimeout = version[1] < SEND_RACE_BL
        @_setCurrentState(States.LoadingBootloaderReloader)
        @_handleCurrentState()

  _processLoadOs: ->
    @_isOsLoaded = no
    @_findOriginalKey(ledger.fup.updates.OS_LOADER).then (offset) =>
      @_isWaitForDongleSilent = yes
      @_processLoadingScript(ledger.fup.updates.OS_LOADER[offset], States.LoadingOs).then (result) =>
        @_isOsLoaded = yes
        _.delay (=> @_waitForPowerCycle(null, yes)), 200
      .fail (e) =>
        @_isWaitForDongleSilent = no
        @_setCurrentState(States.Undefined)
        @_failure(Errors.CommunicationError)
    .fail (e) =>
      @_isWaitForDongleSilent = no
      @_setCurrentState(States.Undefined)

  _processLoadBootloader: ->
    @_findOriginalKey(ledger.fup.updates.BL_LOADER).then (offset) =>
      @_processLoadingScript(ledger.fup.updates.BL_LOADER[offset], States.LoadingBootloader)
    .then => @_waitForPowerCycle(null, yes)
    .fail (ex) =>
      @_failure(Errors.CommunicationError)

  _processLoadBootloaderReloader: ->
    @_findOriginalKey(ledger.fup.updates.RELOADER_FROM_BL).then (offset) =>
      @_processLoadingScript(ledger.fup.updates.RELOADER_FROM_BL[offset], States.LoadingBootloaderReloader)
    .then => @_waitForPowerCycle(null, yes)
    .fail (ex) =>
      @_failure(ledger.errors.CommunicationError)

  _getVersion: (forceBl, callback) -> @_dongle.getRawFirmwareVersion(@_lastMode is Modes.Bootloader, forceBl, callback)

  _failure: (reason) ->
    @emit "error", cause: ledger.errors.new(reason)
    @_waitForPowerCycle()
    return

  _success: ->
    @_setCurrentState(States.Done)
    _.defer => @cancel()

  _attemptToFailDonglePinCode: (pincode) ->
    deferred = Q.defer()
    @_dongle.unlockWithPinCode pincode, (isUnlocked, error) =>
      if isUnlocked or error.code isnt ledger.errors.WrongPinCode
        @emit "erasureStep", 3
        @_waitForPowerCycle().then -> deferred.reject()
      else
        @emit "erasureStep", error.retryCount
        @_waitForPowerCycle()
        .then =>
          @_dongle.getState (state) =>
            deferred.resolve(state is ledger.dongle.States.BLANK or state is ledger.dongle.States.FROZEN)
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
      Q()
    else
      @_setIsNeedingUserApproval yes
      @_deferredApproval.promise.then => @_approvedStates.push approvalName

  _removeUserApproval: (approvalName) ->
    @_approvedStates = _(@_approvedStates).without(approvalName)
    return

  _processLoadingScript: (adpus, state, ignoreSW, offset = 0) ->
    d = ledger.defer()
    @_doProcessLoadingScript(adpus, state, ignoreSW, offset).then(-> d.resolve()).fail((ex) -> d.reject(ex))
    d.promise

  _doProcessLoadingScript: (adpus, state, ignoreSW, offset, forceTimeout = no) ->
    @_notifyProgress(state, offset, adpus.length)
    if offset >= adpus.length
      @_exchangeNeedsExtraTimeout = no
      return
    try
     @_getCard().exchange_async(new ByteString(adpus[offset], HEX))
      .then =>
        if ignoreSW or @_getCard().SW == 0x9000
          if @_exchangeNeedsExtraTimeout or forceTimeout
            deferred = Q.defer()
            _.delay (=> deferred.resolve(@_doProcessLoadingScript(adpus, state, ignoreSW, offset + 1))), ExchangeTimeout
            deferred.promise
          else
            @_doProcessLoadingScript(adpus, state, ignoreSW, offset + 1)
        else
          @_exchangeNeedsExtraTimeout = no
          if forceTimeout is no
            @_doProcessLoadingScript(adpus, state, ignoreSW, offset, yes)
          else
            throw new Error('Unexpected status ' + @_getCard().SW)
      .fail (ex) =>
        return @_doProcessLoadingScript(adpus, state, ignoreSW, offset + 1) if offset is adpus.length - 1
        @_exchangeNeedsExtraTimeout = no
        if forceTimeout is no
          @_doProcessLoadingScript(adpus, state, ignoreSW, offset, yes)
        else
          throw new Error("ADPU sending failed " + ex)
    catch ex
      e ex

  _findOriginalKey: (loadingArray, offset = 0) ->
    throw new Error("Key not found") if offset >= loadingArray.length
    @_getCard().exchange_async(new ByteString(loadingArray[offset][0], HEX)).then (result) =>
      if @_getCard().SW == 0x9000
        offset
      else
        @_findOriginalKey(loadingArray, offset + 1)
    .fail (er) =>
      e er
      throw new Error("Communication Error")

  _getCard: -> @_dongle?._btchip.card

  _notifyProgress: (state, offset, total) -> _.defer => @_onProgress?(state, offset, total)
