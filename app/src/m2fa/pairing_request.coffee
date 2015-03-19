
@ledger.m2fa ?= {}

###
  Wrapper around the pairing API. The pairing request ensures process consistency and will complete with a failure if any
  of the protocol step is broken. The pairing request fire events in order to follow up the current step and provide an
  internal state.

  @event 'join' Notifies that a client joined the room and attempts to create a secure channel
  @event 'sendChallenge' Notifies that the dongle is challenging the client
  @event 'answerChallenge' Notifies that a client answered to the dongle challenge
  @event 'finalizing' Notifies that the pairing is successful and the application is about to store the secure screen in the user preferences
  @event 'error' Notifies pairing error. Use 'reason' key in data to retrieve the error reason.
  @event 'success' Notifies pairing success

###
class @ledger.m2fa.PairingRequest extends @EventEmitter

  @States:
    WAITING: 0
    CHALLENGING: 1
    FINISHING: 2
    DEAD: 3

  @Errors:
    InconsistentState: "inconsistent_state"
    ClientCancelled: "client_cancelled"
    NeedPowerCycle: "dongle_needs_power_cycle"
    InvalidChallengeResponse: "invalid_challenge_response"
    Cancelled: "dongle_cancelled"
    UnknownError: "unknown"

  constructor: (pairindId, promise, client) ->
    @pairingId = pairindId
    @_client = client
    @_secureScreenName = new CompletionClosure()
    @_client.pairedDongleName = @_secureScreenName
    @_currentState = ledger.m2fa.PairingRequest.States.WAITING
    @_onComplete = new CompletionClosure()
    @_identifyData = {}

    promise.then(
      (result) =>
        @_success(result)
      ,
      (err) =>
        _.defer =>
          try
            failure = switch err
              when 'invalidChallenge' then ledger.m2fa.PairingRequest.Errors.InvalidChallengeResponse
              when 'cancel' then ledger.m2fa.PairingRequest.Errors.Cancelled
              when 'initiateFailure' then ledger.m2fa.PairingRequest.Errors.NeedPowerCycle
              else ledger.m2fa.PairingRequest.Errors.UnknownError
            @_failure(failure)
          catch er
            e er
      ,
      (progress) =>
        try
          switch progress
            when 'pubKeyReceived'
              @_identifyData = _.clone(@_client.lastIdentifyData)
              return @_failure(ledger.m2fa.PairingRequest.Errors.InconsistentState) if @_currentState isnt ledger.m2fa.PairingRequest.States.WAITING
              @_currentState = ledger.m2fa.PairingRequest.States.CHALLENGING
              @emit 'join'
            when 'challengeReceived'
              return @_failure(ledger.m2fa.PairingRequest.Errors.InconsistentState) if @_currentState isnt ledger.m2fa.PairingRequest.States.CHALLENGING
              @_currentState = ledger.m2fa.PairingRequest.States.FINISHING
              @emit 'answerChallenge'
            when 'secureScreenDisconnect'
              @_failure(ledger.m2fa.PairingRequest.Errors.ClientCancelled) if @_currentState isnt ledger.m2fa.PairingRequest.States.WAITING
            when 'sendChallenge' then @emit 'sendChallenge'
            when 'secureScreenConfirmed' then @emit 'finalizing'
        catch er
          e er
    ).done()
    @_client.on 'm2fa.disconnect'
    @_promise = promise

  # Sets the completion callback.
  # @param [Function] A callback to call once the pairing process is completed
  onComplete: (cb) -> @_onComplete.onComplete(cb)

  # Sets the secure screen name. This is a mandatory step for saving the paired secure screen
  setSecureScreenName: (name) -> @_secureScreenName.success(name)

  getCurrentState: () -> @_currentState

  getSuggestedDeviceName: -> @_identifyData?['name']

  getDeviceUuid: -> @_identifyData?['uuid']

  cancel: () ->
    @_promise = null
    @_secureScreenName.failure('cancel')
    @_client.stopIfNeccessary()
    @_onComplete = new CompletionClosure()
    @emit 'cancel'
    do @off

  _failure: (reason) ->
    @_currentState = ledger.m2fa.PairingRequest.States.DEAD
    unless @_onComplete.isCompleted()
      @_onComplete.failure(reason)
      @emit 'error', {reason: reason}

  _success: (screen) ->
    @_currentState = ledger.m2fa.PairingRequest.States.DEAD
    unless @_onComplete.isCompleted()
      @_onComplete.success(screen)
      @emit 'success'