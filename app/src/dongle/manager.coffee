
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
    return
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
      oldDongles = @_dongles
      newIds = device.device || device.deviceId for device in devices
      for id in newIds when ! @_dongles[id]?
        @_connectDongle(id)
      for dongle in @_dongles when newIds.indexOf(dongle.device_id) == -1
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

  _connectDongle: (device_id) ->
    try
      @cardFactory.list_async().then (result) =>
        setTimeout =>
          if result.length > 0
            @cardFactory.getCardTerminal(result[0]).getCard_async().then (card) =>
              setTimeout () =>
                @_dongles[device_id] = new ledger.wallet.Dongle(device_id, card)
                @_dongles[device_id].once 'state:locked', (event, dongle) =>
                  @emit 'connected', dongle
                @_dongles[device_id].once 'state:disconnected', (event, dongle) =>
                  delete @_dongle[dongle.device_id]
                  @emit 'disconnected', dongle

        , 0
    catch er
      e er

  getConnectedDongle: -> _(_.values(@_dongles)).filter (w) -> w._state isnt ledger.wallet.States.DISCONNECTED
