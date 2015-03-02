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

###
  FirmwareUpdateRequest performs dongle firmware updates. Once started it will listen the {WalletsManager} in order to catch
  connected dongles and update them. Only one instance of FirmwareUpdateRequest should be alive at the same time. (This is
  ensured by the {ledger.fup.FirmwareUpdater})
###
class ledger.fup.FirmwareUpdateRequest extends @EventEmitter

  @States: States

  @Modes: Modes

  @Errors: Errors

  constructor: (firmwareUpdater) ->
    @_fup = firmwareUpdater
    @_completion = new CompletionClosure()
    @_currentState = _(@).getClass().States.Undefined
    @_waitForConnectedDongle()

  ###
    Stops all current tasks and listened events.
  ###
  cancel: () -> @_fup._cancelRequest(this)

  onComplete: (callback) -> @_completion.onComplete callback

  _waitForConnectedDongle: (callback = _.noop) ->
    completion = new CompletionClosure(callback)

    registerWallet = (wallet) =>
      @_wallet = wallet
      wallet.once 'disconnected', => @_wallet = null
      completion.success(wallet)

    [wallet] = ledger.app.walletsManager.getAllWallets()
    unless wallet?
      ledger.app.walletsManager.once 'connected', (e, wallet) => registerWallet(wallet)
    else
      registerWallet(wallet)
    completion.readonly()

  _waitForDisconnectDongle: ->
    ledger.app.walletsManager.once 'disconnect', =>

  _handleCurrentState: () ->
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

