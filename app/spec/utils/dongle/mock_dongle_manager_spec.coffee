@ledger.dongle ?= {}

class ledger.dongle.MockDongleManager extends EventEmitter

  # connected dongles
  _dongles: []

  # Start observing if dongles are plugged in or unnplugged
  start: () ->
    #return if @_running
    l 'start'
    #@_running = yes
    #@_interval = setInterval @_checkIfDongleIsPluggedIn.bind(@), 200

  # Stop observing dongles state
  stop: () ->
    l 'stop'
    #clearInterval @_interval

  # Create Dongle, observe dongle state and emit corresponding events
  createDongle: () ->
    dongle = new ledger.dongle.MockDongle()
    dongle.id = @_dongles.length + 1
    @_dongles.push(dongle)
    @emit 'connecting'
    dongle.once 'state:locked', (event) => @emit 'connected', dongle
    dongle.once 'state:blank', (event) => @emit 'connected', dongle
    dongle.once 'forged', (event) => @emit 'forged', dongle
    dongle.once 'state:disconnected', (event) =>
      @_dongles.pop()
      @emit 'disconnected', dongle

  # Get the list of dongles
  # @return [Array] the list of dongles
  dongles: () ->
    @_dongles


