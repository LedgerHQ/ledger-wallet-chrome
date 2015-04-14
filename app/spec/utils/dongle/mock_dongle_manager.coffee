@ledger.dongle ?= {}

class ledger.dongle.MockDongleManager extends EventEmitter

  dongleInstance: undefined
  # connected dongles
  _dongles: []

  # Start observing if dongles are plugged in or unnplugged
  start: () ->
    l 'start'

  # Stop observing dongles state
  stop: () ->
    l 'stop'

  # Create Dongle, observe dongle state and emit corresponding events
  createDongle: (pin, seed) ->
    @dongleInstance = new ledger.dongle.MockDongle(pin, seed)
    @dongleInstance.id = @_dongles.length + 1
    @dongleInstance.deviceId = @dongleInstance.id
    @_dongles.push(@dongleInstance)
    #@emit 'connecting', @dongleInstance
    #@emit 'connected', @dongleInstance
    @dongleInstance.once 'state:locked', (event) => @emit 'connected', @dongleInstance
    @dongleInstance.once 'state:blank', (event) => @emit 'connected', @dongleInstance
    @dongleInstance.once 'forged', (event) => @emit 'forged', @dongleInstance
    @dongleInstance.once 'state:disconnected', (event) =>
      @_dongles.pop()
      @emit 'disconnected', @dongleInstance

  # Simulates Remove/Put the dongle
  powerCycle: (delay) ->
    @emit 'disconnected', @dongleInstance
    setTimeout =>
      @emit 'connecting', @dongleInstance
      @emit 'connected', @dongleInstance
    , delay


  # Get the list of dongles
  # @return [Array] the list of dongles
  dongles: () ->
    @_dongles


