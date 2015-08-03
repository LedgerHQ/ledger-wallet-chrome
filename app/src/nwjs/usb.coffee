return unless global?.require?

USB = null #global.require("node-USB")

empty = (msg) ->
  e "#{msg}: Not implemented"
  throw new Error("#{msg}: Not implemented")

@ledger ||= {}
@ledger.nwjs ||= {}
@ledger.nwjs.usb ||= {}

_.extend ledger.nwjs.usb,

  USB: USB

  findDevices: (options, callback) ->
    _.defer -> callback?([])

  getDevices: (options, callback) -> @findDevices(options, callback)

###
  getDevices − chrome.usb.getDevices(object options, function callback)
  getUserSelectedDevices − chrome.usb.getUserSelectedDevices(object options, function callback)
  requestAccess − chrome.usb.requestAccess( Device device, integer interfaceId, function callback)
  openDevice − chrome.usb.openDevice( Device device, function callback)
  findDevices − chrome.usb.findDevices(object options, function callback)
  closeDevice − chrome.usb.closeDevice( ConnectionHandle handle, function callback)
  setConfiguration − chrome.usb.setConfiguration( ConnectionHandle handle, integer configurationValue, function callback)
  getConfiguration − chrome.usb.getConfiguration( ConnectionHandle handle, function callback)
  listInterfaces − chrome.usb.listInterfaces( ConnectionHandle handle, function callback)
  claimInterface − chrome.usb.claimInterface( ConnectionHandle handle, integer interfaceNumber, function callback)
  releaseInterface − chrome.usb.releaseInterface( ConnectionHandle handle, integer interfaceNumber, function callback)
  setInterfaceAlternateSetting − chrome.usb.setInterfaceAlternateSetting( ConnectionHandle handle, integer interfaceNumber, integer alternateSetting, function callback)
  controlTransfer − chrome.usb.controlTransfer( ConnectionHandle handle, object transferInfo, function callback)
  bulkTransfer − chrome.usb.bulkTransfer( ConnectionHandle handle, GenericTransferInfo transferInfo, function callback)
  interruptTransfer − chrome.usb.interruptTransfer( ConnectionHandle handle, GenericTransferInfo transferInfo, function callback)
  isochronousTransfer − chrome.usb.isochronousTransfer( ConnectionHandle handle, object transferInfo, function callback)
  resetDevice − chrome.usb.resetDevice( ConnectionHandle handle, function callback)
###

# Expose ledger.nwjs.hid as chrome.hid
(@chrome ||= {}).usb = @ledger.nwjs.usb