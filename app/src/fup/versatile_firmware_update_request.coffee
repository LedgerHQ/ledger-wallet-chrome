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