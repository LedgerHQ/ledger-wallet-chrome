ledger.fup ?= {}

States =
  Undefined: 0
  Erasing: 1
  ReloadingBootloaderFromOs: 2
  LoadingBootloader: 3
  LoadingReloader: 4
  LoadingOs: 5
  InitializingOs: 6
  Done: 7

Modes =
  Os: 0
  Bootloader: 1

Errors =
  InconsistentState: "InconsistentState"
  InvalidSeedSize: "Invalid seed size. The seed must have 32 characters"
  InvalidSeedFormat: "Invalid seed format. The seed must represent a hexadecimal value"

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

  constructor: (firmwareUpdater) ->
    @_fup = firmwareUpdater
    @_keyCardSeed = null
    @_completion = new CompletionClosure()
    @_currentState = States.Undefined
    @_isNeedingUserApproval = no
    @_lastMode = Modes.Os
    @_lastVersion = undefined

  ###
    Stops all current tasks and listened events.
  ###
  cancel: () -> @_fup._cancelRequest(this)

  onComplete: (callback) -> @_completion.onComplete callback

  ###
    Approves the current request state and continue its execution.
  ###
  approveCurrentState: -> @_setIsNeedingUserApproval no

  isNeedingUserApproval: -> @_isNeedingUserApproval

  ###
    Sets the key card seed used during the firmware update process. The seed must be a 32 characters string formatted as
    an hexadecimal value.

    @param [String] keyCardSeed A 32 characters string formatted as an hexadecimal value (i.e. '01294b7431234b5323f5588ce7d02703'
    @throw If the seed length is not 32 or if it is malformed
  ###
  setKeyCardSeed: (keyCardSeed) ->
    throw Errors.InvalidSeedSize if not keyCardSeed? or keyCardSeed.length != 32
    seed = Try => new ByteString(keyCardSeed, HEX)
    throw Errors.InvalidSeedFormat if seed.isFailure() or seed.getValue()?.length != 16
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

  _waitForConnectedDongle: (callback = undefined) ->
    completion = new CompletionClosure(callback)
    registerWallet = (wallet) =>
      @_wallet = wallet
      wallet.once 'disconnected', => @_wallet = null
      completion.success(wallet)

    [wallet] = ledger.app.walletsManager.getConnectedWallets()
    try
      unless wallet?
        _.defer => @emit 'plug'
        ledger.app.walletsManager.once 'connected', (e, wallet) =>
          registerWallet(wallet)
      else
        registerWallet(wallet)
    catch er
      e er
    completion.readonly()

  _waitForDisconnectDongle: (callback = undefined) ->
    completion = new CompletionClosure(callback)
    if @_wallet?
      @emit 'unplug'
      @_wallet.once 'disconnected', =>
        @_wallet = null
        completion.success()
    else
      completion.success()
    completion.readonly()

  _waitForPowerCycle: (callback = undefined ) -> @_waitForDisconnectDongle().then(=> @_waitForConnectedDongle(callback).promise())

  _handleCurrentState: () ->
    # If there is no dongle wait for one
    (return @_waitForConnectedDongle => @_handleCurrentState()) unless @_wallet

    # Otherwise handle the current by calling the right method depending on the last mode and the state
    if LastMode is Modes.Os
      switch @_currentState
        when States.Undefined then do @_processInitStageOs
        when States.ReloadingBootloaderFromOs then do @_processReloadBootloaderFromOs
        when States.InitializingOs then do @_processInitOs
        when States.Erasing then do @_processErasing
        else @_failure(Errors.InconsistentState)
    else
      switch @_currentState
        when States.Undefined then do @_processInitStageBootloader
        when States.LoadingBootloader then null

  _processInitStageOs: ->
    @_wallet.getState (state) =>
      if state isnt ledger.wallet.States.BLANK and state isnt ledger.wallet.States.FROZEN
        @_setCurrentState(States.Erasing)
        @_handleCurrentState()
      else
        @_getVersion()

  _processErasing: ->
    @_waitForUserApproval()
    .then =>
      getRandomChar = -> "0123456789".charAt(_.random(10))
      deferred = Q.defer()
      pincode = getRandomChar() + getRandomChar()
      failUntilDongleIsBlank = =>
        @_attemptToFailDonglePinCode(pincode)
        .then (isBlank) =>
          l 'IS BLANK', isBlank
          if isBlank then deferred.resolve() else failUntilDongleIsBlank()
        .fail =>
          pincode += getRandomChar()
          failUntilDongleIsBlank()
        .done()
      failUntilDongleIsBlank()
      deferred.promise
    .then =>
      @_setCurrentState(States.Undefined)
      @_handleCurrentState()
    .fail ->
      l 'FAIL', arguments
    .done()

  _processInitOs: ->

  _processReloadBootloaderFromOs: ->

  _processInitStageBootloader: ->

  _getVersion: (forceBl, callback) -> @_wallet.getRawFirmwareVersion(@_lastMode is Modes.Bootloader, forceBl, callback)

  _compareVersion: (v1, v2) ->

  _failure: (reason) ->

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
        @_defferedApproval = Q.defer()
      else
        defferedApproval = @_defferedApproval
        @_defferedApproval = null
        defferedApproval.resolve()
    return

  _cancelApproval: ->
    if @_isNeedingUserApproval
      @_isNeedingUserApproval = no
      defferedApproval = @_defferedApproval
      @_defferedApproval = null
      defferedApproval.reject("cancelled")

  _waitForUserApproval: ->
    @_setIsNeedingUserApproval  yes
    @_defferedApproval.promise



LastMode = ledger.fup.FirmwareUpdateRequest.Modes.Os

