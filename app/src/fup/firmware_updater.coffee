
ledger.fup ?= {}

###

###
class ledger.fup.FirmwareUpdater

  instance: new @

  isFirmwareUpdateAvailable: (wallet) -> yes

  requestFirmwareUpdate: () ->
