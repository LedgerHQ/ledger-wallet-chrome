return unless @electron?

(@chrome ||= {}).usb ||= {}

_.extend chrome.usb,

  getDevices: ->