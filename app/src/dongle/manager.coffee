
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
    @_dongles = {}
    @_cardFactories = {}

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
    _.values(@_dongles).filter (d) -> d?

  _checkIfDongleIsPluggedIn: () ->
    @_getDevices (devices) =>
      for device in devices
        device.deviceId = parseInt(device.deviceId || device.device)
        continue if ! device.deviceId
        @_connectDongle(device) unless @_dongles.hasOwnProperty(device.deviceId)
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

  _connectDongle: (device) ->
    device.isInBootloaderMode = _.contains([0x1807, 0x1808], device.productId)
    @_cardFactories[((device.productId << 16) | device.vendorId) >>> 0] ?= new ChromeapiPlugupCardTerminalFactory(if device.isInBootloaderMode then device.productId else undefined)
    @_dongles[device.deviceId] = null
    @emit 'connecting', device
    result = []
    @_cardFactories[((device.productId << 16) | device.vendorId) >>> 0].list_async().then (result) =>
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
        return

  getConnectedDongles: -> _(_.values(@_dongles)).filter (d) -> d? && d.state isnt ledger.dongle.States.DISCONNECTED
