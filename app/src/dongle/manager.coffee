
@ledger.dongle ?= {}

DevicesInfo = [
  {productId: 0x1b7c, vendorId: 0x2581, type: 'usb', scanner: 'WinUsb'}
  {productId: 0x2b7c, vendorId: 0x2581, type: 'hid', scanner: 'LegacyHid'}
  {productId: 0x3b7c, vendorId: 0x2581, type: 'hid', scanner: 'Hid'}
  {productId: 0x1808, vendorId: 0x2581, type: 'usb', scanner: 'WinUsbBootloader'}
  {productId: 0x1807, vendorId: 0x2581, type: 'hid', scanner: 'HidBootloader'}
]

{$error} = ledger.utils.Logger.getLazyLoggerByTag("ledger.dongle.Manager")

# A dongle manager for keeping the dongles registry and observing dongle state.
# It emits events when a dongle is plugged in and when it is unplugged
# @event plug Emitted when the dongle is plugged in
# @event unplug Emitted when the dongle is unplugged
class @ledger.dongle.Manager extends EventEmitter
  DevicesInfo: DevicesInfo

  _running: no
  _dongles: {}
  _scanning: []

  constructor: (app) ->
    @_dongles = {}
    @_factoryDongleBootloader = new ChromeapiPlugupCardTerminalFactory(0x1808);
    @_factoryDongleBootloaderHID = new ChromeapiPlugupCardTerminalFactory(0x1807);
    @_factoryDongleBootloaderHIDNew = new ChromeapiPlugupCardTerminalFactory(0x3b7c);
    @_factoryDongleOS = new ChromeapiPlugupCardTerminalFactory(0x1b7c);
    @_factoryDongleOSHID = new ChromeapiPlugupCardTerminalFactory(0x2b7c);
    @_factoryDongleOSHIDLedger = new ChromeapiPlugupCardTerminalFactory(0x3b7c, undefined, true);

  # Start observing if dongles are plugged in or unnplugged
  start: () ->
    return if @_running
    @_running = yes
    @_interval = setInterval @_checkIfDongleIsPluggedIn.bind(@), 200

  # Stop observing dongles state
  stop: () ->
    @_running = no
    clearInterval @_interval

  # Get the list of dongles
  # @return [Array] the list of dongles
  dongles: () ->
    _.values(@_dongles).filter (d) -> d?

  _checkIfDongleIsPluggedIn: () ->
    @_getDevices (devices) =>
      for device in devices
        device.deviceId = parseInt(device.deviceId || device.device)
        continue if ! device.deviceId
        @_scanDongle(device) if !@_dongles.hasOwnProperty(device.deviceId) and !_(@_scanning).contains(device.deviceId)
      for id, dongle of @_dongles when _(devices).where(deviceId: +id).length == 0
        dongle.disconnect() if dongle?

  _getDevices: (cb) ->
    devices = []
    _.async.each DevicesInfo, (device, next, hasNext) ->
      type = if device.type is "usb" then chrome.usb else chrome.hid
      info = {productId: device.productId, vendorId: device.vendorId}
      type.getDevices info, (d) ->
        devices = devices.concat(d)
        cb?(devices) if !hasNext or devices.length > 0
        next()

  _scanDongle: (device) ->
    @_scanning.push device.deviceId
    @emit 'connecting', device
    scanner = _(DevicesInfo).find((info) -> info.productId is device.productId and info.vendorId is device.vendorId).scanner
    l "_scanDongle#{scanner}"
    @["_scanDongle#{scanner}"](device).then ([terminal, isInBootloaderMode]) =>
      terminal.getCard_async().then (card) =>
        @_connectDongle(card, device, isInBootloaderMode)
    .fail (error) =>
      $error("Failed to connect dongle: ", error?.message or error)
      @emit 'failed:connecting'
    .finally =>
      @_scanning = _(@_scanning).without(device.deviceId)

  _scanDongleWinUsb: ->
    @_factoryDongleOS.list_async().then (result) =>
      if result.length > 0
        [@_factoryDongleOS.getCardTerminal(result[0]), no]
      else
        throw new Error("Factory dongle OS (USB) failed")

  _scanDongleWinUsbBootloader: ->
    @_factoryDongleBootloader.list_async().then (result) =>
      if result.length > 0
        [@_factoryDongleBootloader.getCardTerminal(result[0]), yes]
      else
        throw new Error("Factory dongle Bootloader (USB) failed")

  _scanDongleLegacyHid: ->
    @_factoryDongleOSHID.list_async().then (result) =>
      if result.length > 0
        [@_factoryDongleOSHID.getCardTerminal(result[0]), no]
      else
        throw new Error("Factory dongle Legacy (HID) failed")

  _scanDongleBootloaderHid: ->
    @_factoryDongleBootloaderHID.list_async().then (result) =>
      if result.length > 0
        [@_factoryDongleBootloaderHID.getCardTerminal(result[0]), yes]
      else
        throw new Error("Factory dongle Bootloader (HID) failed")

  _scanDongleHid: ->
    @_factoryDongleBootloaderHIDNew.list_async().then (result) =>
      if result.length > 0
        @_factoryDongleBootloaderHIDNew.getCardTerminal(result[0])
      else
        throw new Error("Factory dongle Bootloader HID new failed")
    .then (terminal) =>
      l "AFTER HID NEW"
      terminal.getCard_async().then (card) ->
        apdu = new ByteString("F001000000", HEX)
        card.exchange_async(apdu).then (result) =>
          l "Begin exchange check"
          if result.byteAt(0) != 0xF0
            [{getCard_async: -> ledger.defer().resolve(card).promise}, yes]
          else
            throw new Error()
        .fail (error) =>
          l "Not in BL disconnect"
          card.disconnect_async().then -> throw new Error()
    .fail () =>
      l "Connect OS card"
      @_factoryDongleOSHIDLedger.list_async().then (result) =>
        if result.length > 0
         [@_factoryDongleOSHIDLedger.getCardTerminal(result[0]), no]
        else
          throw new Error("Factory dongle Bootloader HID new failed")

  _connectDongle: (card, device, isInBlMode) ->
    _.extend card, deviceId: device.deviceId, productId: device.productId, vendorId: device.vendorId
    dongle = new ledger.dongle.Dongle(card)
    @_dongles[device.deviceId] = dongle
    l "Connect ", arguments
    dongle.connect(isInBlMode).then (state) =>
      l "Connection done", state
      States = ledger.dongle.States
      switch state
        when States.LOCKED then @emit 'connected', dongle
        when States.BLANK then @emit 'connected', dongle
      l "Connection done", state
    .fail (error) =>
      e "Connection failed", error
      @emit 'connection:failure', error
    .done()
    dongle.once 'forged', (event) => @emit 'forged', dongle
    dongle.once 'state:disconnected', (event) =>
      delete @_dongles[device.deviceId]
      @emit 'disconnected', dongle
    return

  getConnectedDongles: -> _(_.values(@_dongles)).filter (d) -> d? && d.state isnt ledger.dongle.States.DISCONNECTED
