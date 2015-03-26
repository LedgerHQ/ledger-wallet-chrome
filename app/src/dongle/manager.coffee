
@ledger.dongle ?= {}

DevicesInfo = [
  {productId: 0x1b7c, vendorId: 0x2581, type: 'usb'}
  {productId: 0x2b7c, vendorId: 0x2581, type: 'hid'}
  {productId: 0x3b7c, vendorId: 0x2581, type: 'hid'}
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
      pluggedIds = (device.device || device.deviceId for device in devices)
      for id in pluggedIds when ! @_dongles[id]?
        @_connectDongle(id)
      for id, dongle of @_dongles when pluggedIds.indexOf(+id) == -1
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

  _connectDongle: (deviceId) ->
    try
      @cardFactory.list_async().then (result) =>
        return if result.length == 0
        @cardFactory.getCardTerminal(result[0]).getCard_async().then (card) =>
          console.log("Going to create Dongle", deviceId)
          @_dongles[deviceId] = new ledger.dongle.Dongle(card)
          @_dongles[deviceId].once 'state:locked', (event) =>
            @emit 'connected', @_dongles[deviceId]
          @_dongles[deviceId].once 'state:blank', (event) =>
            @emit 'connected', @_dongles[deviceId]
          @_dongles[deviceId].once 'state:disconnected', (event) =>
            delete @_dongles[deviceId]
            @emit 'disconnected', @_dongles[deviceId]
    catch er
      e er

  getConnectedDongle: -> _(_.values(@_dongles)).filter (w) -> w.state isnt ledger.dongle.States.DISCONNECTED
