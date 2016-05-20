###

###
class ledger.fup.SetupFirmwareUpdateRequest extends ledger.fup.FirmwareUpdateRequest

  constructor: (firmwareUpdater) ->
    super firmwareUpdater, 'OS_LOADER'
