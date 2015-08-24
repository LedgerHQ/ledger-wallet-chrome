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
        device: d.handle, productId: d.deviceDescriptor.idProduct, vendorId: d.deviceDescriptor.idVendor
      callback?(result)

  getDevices: ({productId, deviceId}, callback) ->
    for d in USB.getDeviceList()
      d.deviceId = +_.uniqueId()
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
    _openedDevices[handle].close()
    _openedDevices = _(_openedDevices).omit(handle)
    callback?()

  listInterfaces: (handle, callback) ->

  claimInterface: (handle, interfaceNumber, callback) ->

  releaseInterface: (handle, interfaceNumber, callback) ->

  bulkTransfer: (handle, transferInfo, callback) ->

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
  *getDevices − chrome.usb.getDevices(object options, function callback)
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