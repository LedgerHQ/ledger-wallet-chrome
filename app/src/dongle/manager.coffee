
@ledger.dongle ?= {}

DevicesInfo = [
  {productId: 0x1b7c, vendorId: 0x2581, type: 'usb'}
  {productId: 0x2b7c, vendorId: 0x2581, type: 'hid'}
  {productId: 0x3b7c, vendorId: 0x2581, type: 'hid'}
  {productId: 0x1808, vendorId: 0x2581, type: 'usb'}
  {productId: 0x1807, vendorId: 0x2581, type: 'hid'}
]

# A dongle manager for keeping the dongles registry and observing dongle state.
# It emits events when a dongle is plugged in and when it is unplugged
# @event plug Emitted when the dongle is plugged in
# @event unplug Emitted when the dongle is unplugged
class @ledger.dongle.Manager extends EventEmitter
  DevicesInfo: DevicesInfo

  _running: no
  _dongles: {}

  constructor: (app) ->
    @cardFactory = new ChromeapiPlugupCardTerminalFactory()
    @factoryDongleBootloader = new ChromeapiPlugupCardTerminalFactory(0x1808)
    @factoryDongleBootloaderHID = new ChromeapiPlugupCardTerminalFactory(0x1807)

  # Start observing if dongles are plugged in or unnplugged
  start: () ->
    return if @_running
    _running = yes
    @_interval = setInterval @_checkIfDongleIsPluggedIn.bind(@), 200

  # Stop observing dongles state
  stop: () ->
    clearInterval @_interval

  # Get the list of dongles
  # @return [Array] the list of dongles
  dongles: () ->
    _.values(@_dongles)

  _checkIfDongleIsPluggedIn: () ->
    @_getDevices (devices) =>
      for device in devices
        device.deviceId = parseInt(device.deviceId || device.device)
        @_connectDongle(device) unless @_dongles[device.deviceId]?
      for id, dongle of @_dongles when _(devices).where(deviceId: +id).length == 0
        dongle.disconnect()

  _getDevices: (cb) ->
    devices = []
    _.async.each DevicesInfo, (device, next, hasNext) ->
      type = if device.type is "usb" then chrome.usb else chrome.hid
      info = {productId: device.productId, vendorId: device.vendorId}
      type.getDevices info, (d) ->
        devices = devices.concat(d)
        cb?(devices) unless hasNext
        next()

  _connectDongle: (device) ->
    device.isInBootloaderMode = _.contains([0x1807, 0x1808], device.productId)
    @emit 'connecting', device
    try
      result = []
      @cardFactory.list_async()
      .then (cards) =>
        result = result.concat(cards)
        @factoryDongleBootloader.list_async()
      .then (cards) =>
        result = result.concat(cards)
        @factoryDongleBootloaderHID.list_async()
      .then (cards) =>
        result = result.concat(cards)
        return if result.length == 0
        @cardFactory.getCardTerminal(result[0]).getCard_async().then (card) =>
          _.extend card, deviceId: device.deviceId, productId: device.productId, vendorId: device.vendorId
          dongle = new ledger.dongle.Dongle(card)
          @_dongles[device.deviceId] = dongle
          dongle.once 'state:locked', (event) => @emit 'connected', dongle
          dongle.once 'state:blank', (event) => @emit 'connected', dongle
          dongle.once 'forged', (event) => @emit 'forged', dongle
          dongle.once 'state:disconnected', (event) =>
            delete @_dongles[device.deviceId]
            @emit 'disconnected', dongle
    catch er
      e er

  getConnectedDongles: -> _(_.values(@_dongles)).filter (w) -> w.state isnt ledger.dongle.States.DISCONNECTED
