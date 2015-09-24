
ledger.fup ?= {}

class ledger.fup.Card

  constructor: (card) ->
    @_card = card

  getVersion: ->

  unlockWithPinCode: (pinCode) ->
    @_getCard().exchange_async(new ByteString("E0220000" + Convert.toHexByte(pin.length), HEX).concat(pin)).then (result) =>
      if @_getCard().SW is 0x9000
        @_setCurrentState(States.ReloadingBootloaderFromOs)
        @_handleCurrentState()
        return
      else
        throw Errors.WrongPinCode

  getBtchipInstance: -> @_card

class ledger.fup.Card.Version

  constructor: (version) ->
    @_version = version
    @_firmware = new ledger.dongle.FirmwareInformation(null, version)

  equals: (version) ->

  lt: (version) ->

  gt: (version) ->

  lte: (version) -> @equals(version) or @lt(version)

  gte: (version) -> @equals(version) or @gt(version)

  getFirmwareInformation: -> @_firmware
