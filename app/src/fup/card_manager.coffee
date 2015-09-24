ledger.fup ?= {}

Modes = _.extend _.clone(ledger.fup.FirmwareUpdateRequest.Modes),
  PreferBootloader: 3

class ledger.fup.CardManager

  @ScanDelayMs: 100

  constructor: ->
    @_stopped = no
    @_connectedCard = null
    @_factories =
      bootloader: new ChromeapiPlugupCardTerminalFactory(0x1808)
      hidBootloader: new ChromeapiPlugupCardTerminalFactory(0x1807)
      newHidBootloader: new ChromeapiPlugupCardTerminalFactory(0x3b7c)
      os: new ChromeapiPlugupCardTerminalFactory(0x1b7c)
      osHid: new ChromeapiPlugupCardTerminalFactory(0x2b7c)
      osHidLedger: new ChromeapiPlugupCardTerminalFactory(0x3b7c, undefined, true)

    for key, factory of @_factories
      do (factory) ->
        old_list_async = factory.list_async.bind(factory)
        factory.list_async = ->
          old_list_async().then (result) ->
            if result[0]?.device.productId is factory.pid then [factory, result] else []

  stopWaiting: ->
    @_stopped = yes
    @_deferredWait.reject(ledger.errors.new(ledger.errors.Cancelled))

  waitForInsertion: ->
    return if @_stopped
    @_deferredWait = ledger.defer()
    @_ensureCardDisconnect()
    @_scanDongles().then ({terminal, mode}) =>
      terminal.getCard_async().then (card) =>
        @_connectedCard = card
        @_deferredWait.resolve(card: card, mode: mode)
      .done()
    .fail () =>
      @_deferredWait.resolve(@waitForInsertion())
    .done()
    @_deferredWait.promise

  waitForDisconnection: (silent = no) ->
    return if @_stopped
    @_ensureCardDisconnect()
    @_scanDongles().then ({terminal}) =>
      if !terminal? or silent
        undefined
      else
        ledger.delay(ledger.fup.CardManager.ScanDelayMs)
        .then =>
          @waitForDisconnection(silent)

  waitForPowerCycle: (silent = no) ->
    @_ensureCardDisconnect()
    @waitForDisconnection(silent).then => @waitForInsertion()

  _ensureCardDisconnect: ->
    if @_connectedCard?
      @_connectedCard.disconnect()
      @_connectedCard = null
      yes
    else
      no

  _createScanHandler: ({mode})->
    ([factory, result]) =>
      if result?.length > 0
          mode: mode
          terminal: factory.getCardTerminal(result[0])
          factory: factory
          result: result
      else
        throw ledger.errors.new(ledger.errors.NotFound, "No device found")

  _scanDongles: ->
    @_scanWinUsbDongles().fail =>
      @_scanDongleHid().then (scanResult) =>
        {mode} = scanResult
        if mode is Modes.PreferBootloader
          @_checkForBootloader(scanResult).then (mode) ->
            _.extend(scanResult, mode: mode)
          .fail =>
            @_scanDongleHidOs()
        else
          scanResult
    .fail (error) =>
      if error?.code is ledger.errors.NotFound
        {}
      else
        throw error

  _scanWinUsbDongles: ->
    @_factories.os.list_async()
      .then(@_createScanHandler(mode: Modes.Os))
      .fail => @_factories.bootloader.list_async().then(@_createScanHandler(mode: Modes.Bootloader))

  _scanDongleHid: ->
    @_factories.osHid.list_async()
      .then(@_createScanHandler(mode: Modes.Os))
      .fail => @_factories.newHidBootloader.list_async().then(@_createScanHandler(mode: Modes.PreferBootloader))
      .fail => @_factories.hidBootloader.list_async().then(@_createScanHandler(mode: Modes.Bootloader))

  _scanDongleHidOs: ->
    @_factories.osHidLedger.list_async()
      .then(@_createScanHandler(mode: Modes.Os))

  _checkForBootloader: ({terminal}) ->
    terminal.getCard_async().then (card) ->
      apdu = new ByteString("F001000000", HEX)
      card.exchange_async(apdu).then (result) ->
        if result.byteAt(0) is 0xF0
          throw new Error()
        else
          Modes.Bootloader

