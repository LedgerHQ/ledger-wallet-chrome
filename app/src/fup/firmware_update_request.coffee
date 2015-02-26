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
  This class manages dongle firmware update. It ensures consistent state during the update process


###
class ledger.fup.FirmwareUpdateRequest

  @States: States

  @Modes: Modes

  @Errors: Errors

  constructor: (firmwareUpdater) ->
    @_fup = firmwareUpdater
    @_completion = new CompletionClosure()
    @_currentState = _(@).getClass().States.Undefined

  onComplete: (callback) -> @_completion.onComplete callback

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

