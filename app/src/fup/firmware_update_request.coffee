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
    @_handleCurrentState()

  ###
    Stops all current tasks and listened events.
  ###
  cancel: () -> @_fup._cancelRequest(this)

  onComplete: (callback) -> @_completion.onComplete callback

  ###
    Sets the key card seed used during the firmware update process. The seed must be a 32 characters string formatted as
    an hexadecimal value.

    @param [String] keyCardSeed A 32 characters string formatted as an hexadecimal valeu (i.e. '01294b7431234b5323f5588ce7d02703'
    @throw If the seed length is not 32 or if it is malformed
  ###
  setKeyCardSeed: (keyCardSeed) ->
    throw Errors.InvalidSeedSize if not keyCardSeed? or keyCardSeed.length != 32
    try
      @_keyCardSeed = new ByteString(keyCardSeed, HEX)
    catch er
      throw Errors.InvalidSeedFormat
    return

  _waitForConnectedDongle: (callback = _.noop) ->
    completion = new CompletionClosure(callback)

    registerWallet = (wallet) =>
      @_wallet = wallet
      wallet.once 'disconnected', => @_wallet = null
      completion.success(wallet)

    [wallet] = ledger.app.walletsManager.getAllWallets()
    unless wallet?
      @emit 'plug'
      ledger.app.walletsManager.once 'connected', (e, wallet) => registerWallet(wallet)
    else
      registerWallet(wallet)
    completion.readonly()

  _waitForDisconnectDongle: ->
    return if @_wallet?
    @emit 'unplug'
    ledger.app.walletsManager.once 'disconnect', => @_handleCurrentState()

  _handleCurrentState: () ->
    # If there is no dongle wait for one
    return @_waitForConnectedDongle => @_handleCurrentState() unless @_wallet

    # Otherwise handle the current by calling the right method depending on the last mode and the state
    if LastMode is Modes.Os
      switch @_currentState
        when States.Undefined then do @_processInitStageOs
        when States.ReloadingBootloaderFromOs then do @_processReloadBootloaderFromOs
        when States.InitializingOs then do @_processInitOs
        else @_failure(Errors.InconsistentState)
    else
      switch @_currentState
        when States.Undefined then do @_processInitStageBootloader
        when States.LoadingBootloader then null

  _processInitStageOs: ->

  _processInitOs: ->

  _processReloadBootloaderFromOs: ->

  _processInitStageBootloader: ->

  _getVersion: ->

  _compareVersion: (v1, v2) ->

  _failure: (reason) ->

LastMode = ledger.fup.FirmwareUpdateRequest.Modes.Os

