###

###
class ledger.fup.OperationFirmwareUpdateRequest extends ledger.fup.FirmwareUpdateRequest

  constructor: (firmwareUpdate) ->
    super firmwareUpdate, ledger.fup.updates.OPERATION_OS_LOADER