return unless global?.require?

USB = require("usb")

empty = (msg) ->
  e "#{msg}: Not implemented"
  throw new Error("#{msg}: Not implemented")

@ledger ||= {}
@ledger.nwjs ||= {}
@ledger.nwjs.usb ||= {}

_devices = {}
_openedDevices = {}

_.extend ledger.nwjs.usb,

  USB: USB

  findDevices: (options, callback) ->
    @getDevices options, (devices) =>
      opened = []
      for d in devices
        opened.push @openDevice(d)
      result = _(opened).map (d) ->
        handle: d.handle, productId: d.deviceDescriptor.idProduct, vendorId: d.deviceDescriptor.idVendor
      callback?(result)

  getDevices: ({productId, vendorId}, callback) ->
    _devices = []
    for d in USB.getDeviceList()
      d.deviceId = d.deviceAddress
      _devices[d.deviceId] = d
    result = _(_devices).chain().values().filter (d) ->
      d.deviceDescriptor.idProduct is productId and d.deviceDescriptor.idVendor is vendorId
    .map (d) ->
      device: d.deviceId, productId: d.deviceDescriptor.idProduct, vendorId: d.deviceDescriptor.idVendor
    .value()
    callback?(result)

  openDevice: (d, callback = undefined) ->
    device = _devices[d.device]
    device.handle = +_.uniqueId()
    _openedDevices[device.handle] = device
    device.open()
    callback?()
    device


  closeDevice: (handle, callback) ->
    _openedDevices[handle.handle].close()
    _openedDevices = _(_openedDevices).omit(handle)
    callback?()

  listInterfaces: (handle, callback) ->
    interfaces = _(_openedDevices[handle.handle].interfaces).map (i) ->
      alternateSetting: i.descriptor.bAlternateSetting
      endpoints: _(i.endpoints).map (e) ->
        address: e.bEndpointAddress
        direction: e.direction
        extra_data: e.extra
        maximumPacketSize: e.wMaxPacketSize
        pollingInterval: e.bInterval
        type: ['control', 'isochronous', 'bulk', 'interrupt'][e.transferType]
        usage: 'data'
      extra_data: i.descriptor.extra
      interfaceClass: i.descriptor.bInterfaceClass
      interfaceNumber: i.descriptor.bInterfaceNumber
      interfaceProtocol: i.descriptor.bInterfaceProtocol
      interfaceSubclass: i.descriptor.bInterfaceSubClass

    callback?(interfaces)


  claimInterface: (handle, interfaceNumber, callback) ->
    device = _openedDevices[handle.handle]
    for i in _(device.interfaces).where(id: interfaceNumber)
      i.claim()
    callback?()

  releaseInterface: (handle, interfaceNumber, callback) ->
    device = _openedDevices[handle.handle]
    for i in _(device.interfaces).where(id: interfaceNumber)
      i.release(yes)
    callback?()


  bulkTransfer: (handle, {direction, endpoint, length, data, timeout}, callback) ->
    device = _openedDevices[handle.handle]
    desiredInterface = _(device.interfaces).find (i) ->
      _(i.endpoints).some (e) -> e.transferType is USB.LIBUSB_TRANSFER_TYPE_BULK and e.direction is direction
    endpoint = _(desiredInterface.endpoints).find (e) -> e.direction is direction

    if direction is 'in'
      l "Read data"
      endpoint.transfer length or endpoint.wMaxPacketSize, (error, data) ->
        l "Data read :", data
        callback?(resultCode: (if error? then 1 else 0), data: data)
    else
      l "Send data", new Uint8Array(data)
      endpoint.transfer new Uint8Array(data), (error) ->
        l "RESULT ", arguments
        callback?(resultCode: (if error? then 1 else 0))

  getUserSelectedDevices: (options, callback) -> empty('getUserSelectedDevices')

  requestAccess: (device, interfaceId, callback) -> empty('requestAccess')

  setConfiguration: (handle, configurationValue, callback) -> empty('setConfiguration')

  getConfiguration: (handle, callback) -> empty('getConfiguration')

  setInterfaceAlternateSetting: (handle, interfaceNumber, alternateSetting, callback) -> empty('setInterfaceAlternateSetting')

  controlTransfer: (handle, transferInfo, callback) -> empty('controlTransfer')

  interruptTransfer: (handle, transferInfo, callback) -> empty('interruptTransfer')

  isochronousTransfer: (handle, transferInfo, callback) -> empty('isochronousTransfer')

  resetDevice: (handle, callback) -> empty('resetDevice')

###
  * getDevices − chrome.usb.getDevices(object options, function callback)
  getUserSelectedDevices − chrome.usb.getUserSelectedDevices(object options, function callback)
  requestAccess − chrome.usb.requestAccess( Device device, integer interfaceId, function callback)
  * openDevice − chrome.usb.openDevice( Device device, function callback)
  * findDevices − chrome.usb.findDevices(object options, function callback)
  * closeDevice − chrome.usb.closeDevice( ConnectionHandle handle, function callback)
  setConfiguration − chrome.usb.setConfiguration( ConnectionHandle handle, integer configurationValue, function callback)
  getConfiguration − chrome.usb.getConfiguration( ConnectionHandle handle, function callback)
  * listInterfaces − chrome.usb.listInterfaces( ConnectionHandle handle, function callback)
  * claimInterface − chrome.usb.claimInterface( ConnectionHandle handle, integer interfaceNumber, function callback)
  * releaseInterface − chrome.usb.releaseInterface( ConnectionHandle handle, integer interfaceNumber, function callback)
  setInterfaceAlternateSetting − chrome.usb.setInterfaceAlternateSetting( ConnectionHandle handle, integer interfaceNumber, integer alternateSetting, function callback)
  controlTransfer − chrome.usb.controlTransfer( ConnectionHandle handle, object transferInfo, function callback)
  * bulkTransfer − chrome.usb.bulkTransfer( ConnectionHandle handle, GenericTransferInfo transferInfo, function callback)
  interruptTransfer − chrome.usb.interruptTransfer( ConnectionHandle handle, GenericTransferInfo transferInfo, function callback)
  isochronousTransfer − chrome.usb.isochronousTransfer( ConnectionHandle handle, object transferInfo, function callback)
  resetDevice − chrome.usb.resetDevice( ConnectionHandle handle, function callback)
###

# Expose ledger.nwjs.hid as chrome.hid
(@chrome ||= {}).usb = @ledger.nwjs.usb