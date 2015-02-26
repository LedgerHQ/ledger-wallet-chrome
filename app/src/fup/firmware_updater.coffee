
ledger.fup ?= {}

###
  This class is embedded in {ledger.wallet.HardwareWallet} and is wrapping the whole firmware update process.
###
class ledger.fup.FirmwareUpdater

  constructor: (wallet) ->
    @wallet = wallet

  isFirmwareUpdateAvailable: () ->

  requestFirmwareUpdate: () ->
