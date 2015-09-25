ledger.fup ?= {}

States =
  Undefined: 0
  Erasing: 1
  Unlocking: 2
  SeedingKeycard: 3
  LoadingOldApplication: 4
  ReloadingBootloaderFromOs: 5
  LoadingBootloader: 6
  LoadingReloader: 7
  LoadingBootloaderReloader: 8
  LoadingOs: 9
  InitializingOs: 10
  Done: 11

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
  WrongPinCode: ledger.errors.WrongPinCode

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

  constructor: (firmwareUpdater, osLoader) ->
    @_id = _.uniqueId("fup")
    @_fup = firmwareUpdater
    @_getOsLoader ||= -> ledger.fup.updates[osLoader]
    @_keyCardSeed = null
    @_isRunning = no
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
    @_logger = ledger.utils.Logger.getLoggerByTag('FirmwareUpdateRequest')
    @_lastOriginalKey = undefined
    @_pinCode = undefined
    @_forceDongleErasure = no
    @_cardManager = new ledger.fup.CardManager()

  ###
    Stops all current tasks and listened events.
  ###
  cancel: () ->
    unless @_isCancelled
      @off()
      @_isRunning = no
      @_onProgress = null
      @_isCancelled = yes
      @_getCard()?.disconnect()
      @_fup._cancelRequest(this)
      @_cardManager.stopWaiting()


  onProgress: (callback) -> @_onProgress = callback

  hasGrantedErasurePermission: -> _.contains(@_approvedStates, "erasure")

  ###
    Approves the current request state and continue its execution.
  ###
  approveCurrentState: -> @_setIsNeedingUserApproval no

  isNeedingUserApproval: -> @_isNeedingUserApproval

  ###

  ###
  unlockWithPinCode: (pin) ->
    @_pinCode = pin
    @_approve 'pincode'

  forceDongleErasure: ->
    @_forceDongleErasure = yes
    @_approve 'pincode'

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
    seed = @_keyCardSeedToByteString(keyCardSeed)
    throw seed.getError() if seed.isFailure()
    @_keyCardSeed = seed.getValue()
    @_approve('keycard')
    @emit "setKeyCardSeed"

  ###

  ###
  startUpdate: ->
    return if @_isRunning
    @_isRunning = yes
    @_currentState = States.Undefined
    @_handleCurrentState()

  isRunning: -> @_isRunning

  ###
    Checks if a given keycard seed is valid or not. The seed must be a 32 characters string formatted as
    an hexadecimal value.

    @param [String] keyCardSeed A 32 characters string formatted as an hexadecimal value (i.e. '01294b7431234b5323f5588ce7d02703'
  ###
  checkIfKeyCardSeedIsValid: (keyCardSeed) -> @_keyCardSeedToByteString(keyCardSeed).isSuccess()

  _keyCardSeedToByteString: (keyCardSeed) ->
    Try =>
      throw new Error(Errors.InvalidSeedSize) if not keyCardSeed? or !(keyCardSeed.length is 32 or keyCardSeed.length is 80)
      seed = new ByteString(keyCardSeed, HEX)
      throw new Error(Errors.InvalidSeedFormat) if !seed? or !(seed.length is 16 or seed?.length is 40)
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

  _waitForConnectedDongle: (silent = no) ->
    timeout = @emitAfter('plug',  if !silent then 0 else 200)
    @_cardManager.waitForInsertion(silent).then ({card, mode}) =>
      clearTimeout(timeout)
      @_resetOriginalKey()
      @_lastMode = mode
      @_card = new ledger.fup.Card(card)
      @_setCurrentState(States.Undefined)
      @_handleCurrentState()
      card
    .done()

  _waitForDisconnectDongle: (silent = no) ->
    timeout = @emitAfter('unplug', if !silent then 0  else 500)
    @_cardManager.waitForDisconnection(silent).then =>
      clearTimeout(timeout)
      @_card = null

  _waitForPowerCycle: (callback = undefined, silent = no) -> @_waitForDisconnectDongle(silent).then(=> @_waitForConnectedDongle(silent))

  _handleCurrentState: () ->
    # If there is no dongle wait for one
    return @_waitForConnectedDongle(yes) unless @_card?
    @_logger.info("Handle current state", lastMode: @_lastMode, currentState: @_currentState)

    # Otherwise handle the current by calling the right method depending on the last mode and the state
    if @_lastMode is Modes.Os
      switch @_currentState
        when States.Undefined
          @_findOriginalKey()
            .then => @_processInitStageOs()
            .fail (error) => @_logger.error(error)
            .done()
        when States.ReloadingBootloaderFromOs then do @_processReloadBootloaderFromOs
        when States.InitializingOs then do @_processInitOs
        when States.Erasing then do @_processErasing
        when States.Unlocking then do @_processUnlocking
        when States.SeedingKeycard then do @_processSeedingKeycard
        else @_failure(Errors.InconsistentState)
    else
      switch @_currentState
        when States.Undefined then @_findOriginalKey().then(=> do @_processInitStageBootloader).fail(=> @_failure(Errors.CommunicationError)).done()
        when States.LoadingOs then do @_processLoadOs
        when States.LoadingBootloader then do @_processLoadBootloader
        when States.LoadingBootloaderReloader then do @_processLoadBootloaderReloader
        else @_failure(Errors.InconsistentState)

  _processInitStageOs: ->
    @_logger.info("Process init stage OS")
    @_card.getVersion(Modes.Os, no).then (version) =>
      @_dongleVersion = version
      firmware = version.getFirmwareInformation()
      if !firmware.hasSubFirmwareSupport() and !@_keyCardSeed?
        @_setCurrentState(States.SeedingKeycard)
        @_handleCurrentState()
      else if version.equals(ledger.fup.versions.Nano.CurrentVersion.Os)
        if @_isOsLoaded
          @_setCurrentState(States.InitializingOs)
          @_handleCurrentState()
        else
          @_checkReloadRecoveryAndHandleState(firmware)
      else if version.gt(ledger.fup.versions.Nano.CurrentVersion.Os)
        @_failure(Errors.HigherVersion)
      else
        index = 0
        while index < ledger.fup.updates.OS_INIT.length and !version.equals(ledger.fup.updates.OS_INIT[index][0])
          index += 1
        if index isnt ledger.fup.updates.OS_INIT.length
          @_processLoadingScript(ledger.fup.updates.OS_INIT[index][1], States.LoadingOldApplication, true)
          .then =>
            @_checkReloadRecoveryAndHandleState()
          .fail => @_failure(Errors.CommunicationError)
        else
          @_checkReloadRecoveryAndHandleState(firmware)
    .done()

  _checkReloadRecoveryAndHandleState: (firmware) ->
    handleState = (state) =>
      @_setCurrentState(state)
      @_handleCurrentState()
      return

    if firmware.hasRecoveryFlashingSupport()
      @_getCard().exchange_async(new ByteString("E02280000100", HEX)).then =>
        if ((@_getCard().SW & 0xFFF0) == 0x63C0) && (@_getCard().SW != 0x63C0)
          handleState(States.Unlocking)
        else
          handleState(States.ReloadingBootloaderFromOs)
    else
      handleState(States.ReloadingBootloaderFromOs)
    return

  _processErasing: ->
    @_waitForUserApproval('erasure')
    .then =>
      unless @_stateCache.pincode?
        getRandomChar = -> "0123456789".charAt(_.random(10))
        @_stateCache.pincode = getRandomChar() + getRandomChar()
      pincode = @_stateCache.pincode
      @_card.unlockWithPinCode(pincode).then (isUnlocked, error) =>
        @emit "erasureStep", if error?.retryCount? then error.retryCount else 3
        @_waitForPowerCycle()
      return
    .fail =>
      @_failure(Errors.CommunicationError)
    .done()

  _processUnlocking: ->
    @_waitForUserApproval('pincode')
    .then =>
      if @_forceDongleErasure
        @_setCurrentState(States.Erasing)
        @_handleCurrentState()
      else
        if @_pinCode.length is 0
          @_setCurrentState(States.ReloadingBootloaderFromOs)
          @_handleCurrentState()
          return
        pin = new ByteString(@_pinCode, ASCII)
        @_getCard().exchange_async(new ByteString("E0220000" + Convert.toHexByte(pin.length), HEX).concat(pin)).then (result) =>
          if @_getCard().SW is 0x9000
            @_setCurrentState(States.ReloadingBootloaderFromOs)
            @_handleCurrentState()
            return
          else
            throw Errors.WrongPinCode
    .fail =>
      @_failure(Errors.WrongPinCode)
    .done()

  _processSeedingKeycard: ->
    @_waitForUserApproval('keycard')
    .then =>
      @_setCurrentState(States.Undefined)
      @_handleCurrentState()
    .done()

  _tryToInitializeOs: ->
    continueInitOs = =>
      @_setCurrentState(States.InitializingOs)
      @_handleCurrentState()
    if !@_keyCardSeed?
      @_setCurrentState(States.SeedingKeycard)
      @_waitForUserApproval('keycard')
      .then =>
        @_setCurrentState(States.Undefined)
        do continueInitOs
      .done()
    else
      do continueInitOs

  _processInitOs: ->
    index = 0
    while index < ledger.fup.updates.OS_INIT.length and !ledger.fup.utils.compareVersions(ledger.fup.versions.Nano.CurrentVersion.Os, ledger.fup.updates.OS_INIT[index][0]).eq()
      index += 1
    currentInitScript = INIT_LW_1110
    moddedInitScript = []
    l "NO KEYCARD DAMNIT" unless @_keyCardSeed?
    for i in [0...currentInitScript.length]
      moddedInitScript.push currentInitScript[i]
      if i is currentInitScript.length - 2 and @_keyCardSeed?
        moddedInitScript.push "D026000011" + "04" + @_keyCardSeed.bytes(0, 16).toString(HEX)
        moddedInitScript.push("D02A000018" + @_keyCardSeed.bytes(16).toString(HEX)) if @_keyCardSeed.length > 16
    @_processLoadingScript moddedInitScript, States.InitializingOs, yes
    .then =>
      @_success()
      @_isOsLoaded = no
    .fail =>
      @_failure(Errors.FailedToInitOs)

  _processReloadBootloaderFromOs: ->
    @_removeUserApproval('erasure')
    @_removeUserApproval('pincode')
    @_waitForUserApproval('reloadbootloader')
    .then =>
      @_removeUserApproval('reloadbootloader')
      index = 0
      while index < ledger.fup.updates.BL_RELOADER.length and !@_dongleVersion.equals(ledger.fup.updates.BL_RELOADER[index][0])
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
            l "Failed procces RELOAD BL FROM OS"
            @_processInitOs()
            return
          when 0x6faa then @_failure(Errors.ErrorDueToCardPersonalization)
          else @_failure(Errors.CommunicationError)
        @_waitForDisconnectDongle()
    .fail (err) ->
      console.error(err)

  _processInitStageBootloader: ->
    @_logger.info("Process init stage BL")
    @_lastVersion = null
    @_card.getVersion(Modes.Bootloader, yes).then (version) =>
      return @_failure(Errors.UnableToRetrieveVersion) if error?
      @_lastVersion = version
      if version.equals(ledger.fup.versions.Nano.CurrentVersion.Bootloader)
        @_setCurrentState(States.LoadingOs)
        @_handleCurrentState()
      else
        continueInitStageBootloader = =>
          if version.equals(ledger.fup.versions.Nano.CurrentVersion.Reloader)
            @_setCurrentState(States.LoadingBootloader)
            @_handleCurrentState()
          else
            SEND_RACE_BL = (1 << 16) + (3 << 8) + (11)
            @_exchangeNeedsExtraTimeout = version[1] < SEND_RACE_BL
            @_setCurrentState(States.LoadingBootloaderReloader)
            @_handleCurrentState()

        if !@_keyCardSeed?
          @_setCurrentState(States.SeedingKeycard)
          @_waitForUserApproval('keycard')
          .then =>
            @_setCurrentState(States.Undefined)
            do continueInitStageBootloader
          .done()
        else
          do continueInitStageBootloader


  _processLoadOs: ->
    @_isOsLoaded = no
    @_findOriginalKey().then (offset) =>
      @_isWaitForDongleSilent = yes
      @_processLoadingScript(@_getOsLoader()[offset], States.LoadingOs).then (result) =>
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
    @_findOriginalKey().then (offset) =>
      @_processLoadingScript(ledger.fup.updates.BL_LOADER[offset], States.LoadingBootloader)
    .then => @_waitForPowerCycle(null, yes)
    .fail (ex) =>
      @_failure(Errors.CommunicationError)

  _processLoadBootloaderReloader: ->
    @_findOriginalKey().then (offset) =>
      @_processLoadingScript(ledger.fup.updates.RELOADER_FROM_BL[offset], States.LoadingBootloaderReloader)
    .then => @_waitForPowerCycle(null, yes)
    .fail (ex) =>
      @_failure(ledger.errors.CommunicationError)

  _failure: (reason) ->
    @emit "error", cause: ledger.errors.new(reason)
    @_waitForPowerCycle()
    return

  _success: ->
    debugger
    @_setCurrentState(States.Done)
    _.defer => @cancel()

  _attemptToFailDonglePinCode: (pincode) ->
    deferred = Q.defer()
    @_card.unlockWithPinCode pincode, (isUnlocked, error) =>
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
        @_deferredApproval = Q.defer()
        _.defer => @emit 'needsUserApproval'
      else
        defferedApproval = @_deferredApproval
        @_deferredApproval = null
        defferedApproval.resolve()
    return

  _approve: (approvalName) ->
    l "Approve ", approvalName, " waiting for ", @_deferredApproval?.approvalName
    if @_deferredApproval?.approvalName is approvalName
      @_setIsNeedingUserApproval no
    else
      @_approvedStates.push approvalName

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
      @_deferredApproval.approvalName = approvalName
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
      # BL not responding hack
      if state is States.ReloadingBootloaderFromOs and offset is adpus.length - 1
        @_getCard().exchange_async(new ByteString(adpus[offset], HEX))
        ledger.delay(1000).then => @_doProcessLoadingScript(adpus, state, ignoreSW, offset + 1)
      else
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

  _findOriginalKey: ->
    if @_lastOriginalKey?
      l "Resolve with last key", @_lastOriginalKey
      ledger.defer().resolve(@_lastOriginalKey).promise
    else
      @_getCard().exchange_async(new ByteString("F001010000", HEX), [0x9000]).then (result) =>
        l "CUST ID IS ", result.toString(HEX)
        return if @_getCard().SW isnt 0x9000
        for blCustomerId, offset in ledger.fup.updates.BL_CUSTOMER_ID when result.equals(blCustomerId)
          l "OFFSET IS", offset
          @_lastOriginalKey = offset
          return offset
        @_lastOriginalKey = undefined
        return
      .fail =>
        @_lastOriginalKey = undefined
        return

  _resetOriginalKey: ->
    @_lastOriginalKey = undefined

  _getCard: -> @_card?.getCard()

  _notifyProgress: (state, offset, total) -> _.defer => @_onProgress?(state, offset, total)
