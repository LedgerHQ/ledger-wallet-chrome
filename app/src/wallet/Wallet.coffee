
@ledger.wallet ?= {}

@ledger.wallet.States =
  UNDEFINED: undefined
  LOCKED: 'locked'
  UNLOCKED: 'unlocked'
  FROZEN: 'frozen'
  BLANK: 'blank'
  UNPLUGGED: 'unplugged'

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

  disconnect: () ->


  getState: (callback) ->
    if @_state is ledger.wallet.States.UNDEFINED
      @once 'state:changed', (e, state) => callback?(state)
    else
      callback?(@_state)

  unlockWithPinCode: (pin, callback) ->
    throw 'Cannot unlock a device if its current state is not equal to "ledger.wallet.States.LOCKED"' if @_state isnt ledger.wallet.States.LOCKED
    unbind = @_performLwOperation
      onSuccess:
        events: ['LW.LWPINVerified']
        do:  =>
          @_setState(ledger.wallet.States.UNLOCKED)
          do unbind
          callback?(yes)
      onFailure:
        events: ['LW.ErrorOccured']
        do: (error) =>
          if error.title is 'wrongPIN'
            retryNumber = parseInt(error.message.substr(-1))
            do unbind
            callback?(no, retryNumber)
    @_lwCard.verifyPIN pin

  setup: (pincode, seed, callback) ->
    ###
      onSuccess = () =>
      @once 'connected', =>
        #callback?(yes)

    onFailure = (ev, error) =>
      e error.title
      e error.errors
      if error.title is 'performSetupInvalidData'
        do unbind
      if error.title is 'errorOccuredInSetup'
        callback?(no)
      do unbind

    unbind = () =>
      @_vents.off 'LW.SetupCardInProgress', onSuccess
      @_vents.off 'LW.ErrorOccured', onFailure
    @_vents.on 'LW.SetupCardInProgress', onSuccess
    @_vents.on 'LW.ErrorOccured', onFailure
    ###
    @_lwCard.performSetup(pincode, seed, 'qwerty')

  getBitIdAddress: (callback) ->
    throw 'Cannot get bit id address if the wallet is not unlocked' if @_state isnt ledger.wallet.States.UNLOCKED

    onSuccess = (e, data) =>
      _.defer =>
        @_bitIdData = data.result
        callback?(@_bitIdData.bitcoinAddress.value)
        do unbind

    onFailure = (ev, error) =>
      _.defer =>
        callback?(null, error)
        do unbind

    unbind = =>
      @_vents.off 'LW.getBitIDAddress', onSuccess
      @_vents.off 'LW.ErrorOccured', onFailure
    if @_bitIdData?
      callback?(@_bitIdData.bitcoinAddress.value)
    else
      @_vents.on 'LW.getBitIDAddress', onSuccess
      @_vents.on 'LW.ErrorOccured', onFailure
      @_lwCard.getBitIDAddress()


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
    @_vents.on 'LW.unplugged', () =>
      @_setState ledger.wallet.States.UNPLUGGED
    @_vents.on 'LW.ErrorOccured', (e, data) =>
      switch data.title
        when 'dongleLocked' then @_setState ledger.wallet.States.FROZEN

  _performLwOperation: (operation) ->
    unbind = () =>
      for callbackName, params of operation
        for event in params.events
          @_vents.off event, params.do

    for callbackName, params of operation
      for event in params.events
       do (params) =>
          @_vents.on event, (ev, data) ->
            _.defer () ->
              params.do(data, ev)
    unbind

