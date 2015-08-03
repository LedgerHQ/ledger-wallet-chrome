return unless global?.require?

HID = global.require("node-hid")

empty = (msg) ->
  e "#{msg}: Not implemented"
  throw new Error("#{msg}: Not implemented")

@ledger ||= {}
@ledger.nwjs ||= {}
@ledger.nwjs.hid ||= {}

getManifestUsbDevices = ->
  for permission in ledger.runtime.getManifest().permissions
    return permission['usbDevices'] if permission?['usbDevices']?


pathToDeviceId = (path) -> (pathToDeviceId._cache ||= {})[path] ||= _.str.hashCode(path)
deviceIdToPath =  (deviceId) -> _(pathToDeviceId._cache ||= {}).findKey((i) -> i is deviceId)

_devices = {}

_.extend @ledger.nwjs.hid,

  HID: HID

  getDevices: (options = getManifestUsbDevices(), callback) ->
    devices = []
    options = options.filters if options.filters?
    options = [options] unless _.isArray(options)
    options = _(options)
    for device in HID.devices()
      continue unless options.some((d) -> (!d.productId? or d.productId is device.productId) and (!d.vendorId? or d.vendorId is device.vendorId) and (!d.usagePage? or d.usagePage is device.usagePage))
      devices.push
        collections: [
          {reportIds: [], usage: device.usage, usagePage: device.usagePage}
        ]
        deviceId: pathToDeviceId(device.path)
        maxFeatureReportSize: 0
        maxInputReportSize: 64
        maxOutputReportSize: 64
        productId: device.productId
        reportDescriptor: {}
        vendorId: device.vendorId
    if devices.length is 5
      l "GOT 5", HID.devices(), options
    _.defer -> callback?(devices)
    return

  getUserSelectedDevices: (options, callback) -> empty("getUserSelectedDevices")

  connect: (deviceId, callback) ->
    id = _.uniqueId()
    _devices[id] = new HID.HID(deviceIdToPath(deviceId))
    _devices[id].receptionStream = highland()
    _devices[id].on 'data', (data) -> _devices[id].receptionStream.write(data)
    _devices[id].on 'error', (error) -> ledger.runtime.lastError = error
    _.defer -> callback?(connectionId: id)

  disconnect: (connectionId, callback) ->
    device = _devices[connectionId]
    throw new Error("Connection ##{connectionId} not found") unless device?
    _devices = _.omit(_devices, connectionId)
    device.close()
    _.defer -> callback?()

  receive: (connectionId, callback) ->
    device = _devices[connectionId]
    throw new Error("Connection ##{connectionId} not found") unless device?
    device.receptionStream.pull (err, data) ->
      buffer = new ArrayBuffer(data.length);
      view = new Uint8Array(buffer);
      for i in [0...data.length]
        view[i] = data[i]
      callback?(0, buffer)

  send: (connectionId, reportId, data, callback) ->
    device = _devices[connectionId]
    throw new Error("Connection ##{connectionId} not found") unless device?
    device.write Array.prototype.slice.call(new Uint8Array(data));
    callback?()


  receiveFeatureReport: (connectionId, reportId, callback) -> empty("receiveFeatureReport")

  sendFeatureReport: (connectionId, reportId, data, callback) -> empty("sendFeatureReport")

###
    getDevices − chrome.hid.getDevices(object options, function callback)
    getUserSelectedDevices − chrome.hid.getUserSelectedDevices(object options, function callback)
    connect − chrome.hid.connect(integer deviceId, function callback)
    disconnect − chrome.hid.disconnect(integer connectionId, function callback)
    receive − chrome.hid.receive(integer connectionId, function callback)
    send − chrome.hid.send(integer connectionId, integer reportId, ArrayBuffer data, function callback)
    receiveFeatureReport − chrome.hid.receiveFeatureReport(integer connectionId, integer reportId, function callback)
    sendFeatureReport − chrome.hid.sendFeatureReport(integer connectionId, integer reportId, ArrayBuffer data, function callback)
###

# Expose ledger.nwjs.hid as chrome.hid
(@chrome ||= {}).hid = @ledger.nwjs.hid