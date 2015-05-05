@ledger.dongle ?= {}

class ledger.dongle.MockDongleManager extends EventEmitter

  constructor: ->
    @dongleInstance = undefined
    # connected dongles
    @_dongles = []

  # Start observing if dongles are plugged in or unnplugged
  start: () ->
    l 'start'

  # Stop observing dongles state
  stop: () ->
    l 'stop'

  # Create Dongle, observe dongle state and emit corresponding events
  createDongle: (pin, seed, pairingKeyHex) ->
    @dongleInstance = new ledger.dongle.MockDongle(pin, seed, pairingKeyHex)
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
      l @
      @emit 'disconnected', @dongleInstance

  # Simulates Remove/Put the dongle
  powerCycle: (delay, cb) ->
    @emit 'disconnected', @dongleInstance
    setTimeout =>
      @emit 'connecting', @dongleInstance
      @emit 'connected', @dongleInstance
      cb?()
    , delay


  # Get the list of dongles
  # @return [Array] the list of dongles
  dongles: () ->
    @_dongles


