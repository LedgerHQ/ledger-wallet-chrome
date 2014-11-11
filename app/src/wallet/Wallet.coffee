
@ledger.wallet ?= {}

@ledger.wallet.States =
  UNDEFINED: undefined
  LOCKED: 'locked'
  UNLOCKED: 'unlocked'
  FROZEN: 'frozen'
  BLANK: 'blank'

class @ledger.wallet.Wallet extends EventEmitter

  _state: ledger.wallet.States.UNDEFINED

  constructor: (@id, @lwCard) ->
    @_vents = new EventEmitter()
    do @_listenStateChanges

  connect: () ->
    @_vents.once 'LW.CardConnected', (event, data) =>
      @_vents.once 'LW.FirmwareVersionRecovered', (event, data) =>
        data.lW.getOperationMode()
        data.lW.plugged()
        @emit 'connected', @
      data.lW.recoverFirmwareVersion();
    @_lwCard = new LW(0, new BTChip(@lwCard), @_vents)

  getState: (callback) ->
    if @_state is ledger.wallet.States.UNDEFINED
      @once 'state:changed', (e, state) => callback?(state)
    else
      callback?(@_state)

  unlockWithPinCode: (pin, callback) ->
    throw 'Cannot unlock a device if its current state is not equal to "ledger.wallet.States.LOCKED"' if @_state isnt ledger.wallet.States.LOCKED
    onSuccess = () => 
      do unbind
      callback?(yes)

    onFailure = (e, error) =>
      if error.title is 'wrongPIN'
        do unbind
        callback?(no)

    unbind = () =>
      @_vents.off 'LW.LWPINVerified', onSuccess
      @_vents.off 'LW.ErrorOccured', onFailure
    @_vents.on 'LW.LWPINVerified', onSuccess
    @_vents.on 'LW.ErrorOccured', onFailure
    @_lwCard.verifyPIN pin

  # @param [String] keyboard Either 'azerty' or 'qwerty'
  setup: (pincode, seed, keyboard, callback) ->


  _setState: (newState) ->
    @_state = newState
    switch newState
      when ledger.wallet.States.LOCKED then @emit 'state:locked', @_state
      when ledger.wallet.States.UNLOCKED then @emit 'state:unlocked', @_state
      when ledger.wallet.States.FROZEN then @emit 'state:freezed', @_state
      when ledger.wallet.States.BLANK then @emit 'state:freezed', @_state
    @emit 'state:changed', @_state

  _listenStateChanges: () ->
    @_vents.on 'LW.PINRequired', (e, data) =>
      @_setState ledger.wallet.States.LOCKED
    @_vents.on 'LW.SetupCardLaunched', (e, data) =>
      @_setState ledger.wallet.States.BLANK
    @_vents.on 'LW.ErrorOccured', (e, data) =>
      switch data.title
        when 'dongleLocked' then @_setState ledger.wallet.States.FROZEN
