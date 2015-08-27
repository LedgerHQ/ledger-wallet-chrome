###

###
class ledger.fup.SetupFirmwareUpdateRequest extends ledger.fup.FirmwareUpdateRequest

  constructor: (firmwareUpdate)->
    super firmwareUpdate, ledger.fup.updates.SETUP_OS_LOADER



