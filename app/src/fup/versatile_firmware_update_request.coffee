###

###
class ledger.fup.VersatileFirmwareUpdateRequest extends ledger.fup.FirmwareUpdateRequest

  constructor: (firmwareUpdate) ->
    super firmwareUpdate, 'VERSATILE'
    @_osLoader =  'OPERATION_OS_LOADER'

  _getOsLoader: -> ledger.fup.updates[@_osLoader]

  _processInitStageOs: ->
    @_getVersion().then (version) =>
      firmware = version.getFirmwareInformation()
      if firmware.hasOperationFirmwareSupport()
        @_osLoader =  'OPERATION_OS_LOADER'
      else
        @_osLoader = 'SETUP_OS_LOADER'
      super

  _setCurrentState: (state) ->
    if state is ledger.fup.FirmwareUpdateRequest.States.LoadingBootloader or ledger.fup.FirmwareUpdateRequest.States.LoadingBootloaderReloader
      @_osLoader = 'OPERATION_OS_LOADER'
    super