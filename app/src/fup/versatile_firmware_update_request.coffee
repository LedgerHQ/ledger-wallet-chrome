###

###
class ledger.fup.VersatileFirmwareUpdateRequest extends ledger.fup.FirmwareUpdateRequest

  constructor: (firmwareUpdate) ->
    super firmwareUpdate, 'VERSATILE'
    @_osLoader =  'OPERATION_OS_LOADER'

  _getOsLoader: -> ledger.fup.updates[@_osLoader]

  _processInitStageOs: ->
    if @_dongle.getFirmwareInformation().hasOperationSupport()
      @_osLoader =  'OPERATION_OS_LOADER'
    else
      @_osLoader = 'SETUP_OS_LOADER'
    super

  _setCurrentState: (state) ->
    l "State ", state,  ledger.fup.FirmwareUpdateRequest.States.LoadingBootloader, ledger.fup.FirmwareUpdateRequest.States.LoadingBootloaderReloader
    if state is ledger.fup.FirmwareUpdateRequest.States.LoadingBootloader or ledger.fup.FirmwareUpdateRequest.States.LoadingBootloaderReloader
      l "USE SETUP"
      @_osLoader = 'SETUP_OS_LOADER'
    super