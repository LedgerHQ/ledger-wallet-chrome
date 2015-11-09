
ledger.fup ?= {}

Modes = ledger.fup.FirmwareUpdateRequest.Modes

class ledger.fup.Card

  constructor: (card) ->
    @_card = card

  getVersion: (mode, forceBl)->
    apdu = new ByteString((if mode is Modes.Os then 'E0C4000000' else 'F001000000'), HEX)
    @_card.exchange_async(apdu).then (result) =>
      if mode is Modes.Os and !forceBl
        if @_card.SW is 0x9000
          [result.byteAt(1), (result.byteAt(2) << 16) + (result.byteAt(3) << 8) + result.byteAt(4), result]
        else if @_card.SW is 0x6D00 or @_card.SW is 0x6E00
          @getVersion(mode, true)
      else
        if @_card.SW is 0x9000
          apdu = new ByteString('E001000000', HEX)
          @_card.exchange_async(apdu).then (reloaderResult) =>
            if @_card.SW is 0x9000
              result = reloaderResult
            [0, (result.byteAt(5) << 16) + (result.byteAt(6) << 8) + (result.byteAt(7)), result]
        else if mode is Modes.Os and ((@_card.SW is 0x6D00) or @_card.SW is 0x6E00)
          # Unexpected - let's say it's 1.4.3
          [0, (1 << 16) + (4 << 8) + (3)]
        else
          ledger.errors.new(ledger.errors.UnexpectedResult, "Failed to get version - SW #{@_card.SW}")
    .then (version) =>
      new ledger.fup.Card.Version(version)

  unlockWithPinCode: (pin) ->
    @_card.exchange_async(new ByteString("E0220000" + Convert.toHexByte(pin.length), HEX).concat(new ByteString(pin, ASCII))).then (result) =>
      unless @_card.SW is 0x9000
        error = ledger.errors.new(Errors.WrongPinCode)
        error.remaining = +(@_card.SW.toString(16).match(/63c(.)/i) or [])[1] or 0
        throw error

  getRemainingPinAttempt: ->
    @_card.exchange_async(new ByteString("E02280000100", HEX)).then (result) =>
      statusWord = @_card.SW?.toString(16) or '6985'
      remainingPinAttempt = statusWord.match /63c(\d)/
      if remainingPinAttempt?.length is 2
        +remainingPinAttempt[1]
      else
        throw new Error("Invalid status - #{statusWord}")

  getCard: -> @_card

class ledger.fup.Card.Version

  constructor: (version) ->
    @_version = version
    @_firmware = new ledger.dongle.FirmwareInformation(null, version[2]) if version[2]?

  equals: (version) ->
    return @equals(new ledger.fup.Card.Version(version)) unless _(version).isKindOf(ledger.fup.Card.Version)
    @_version[0] is version._version[0] and @_version[1] is version._version[1]

  lt: (version) ->
    return @equals(new ledger.fup.Card.Version(version)) unless _(version).isKindOf(ledger.fup.Card.Version)
    @_version[0] < version._version[0] and @_version[1] < version._version[1]

  gt: (version) ->
    return @equals(new ledger.fup.Card.Version(version)) unless _(version).isKindOf(ledger.fup.Card.Version)
    @_version[0] < version._version[0] and @_version[1] < version._version[1]

  lte: (version) -> @equals(version) or @lt(version)

  gte: (version) -> @equals(version) or @gt(version)

  getFirmwareInformation: -> @_firmware
