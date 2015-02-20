
@ledger.m2fa ?= {}

# Wrapper around the pairing API. This class defines the followings events:
#   - 'complete'
#   - 'cancel'
#   - 'joined'
#   - 'leave'
class @ledger.m2fa.PairingRequest extends @EventEmitter

  @States:
    WAITING: 0
    CHALLENGING: 1
    FINISHING: 2
    DEAD: 3

  @Errors:
    InconsistentState: "Inconsistent state"
    ClientCancelled: "Client cancelled: consider power cycling your dongle"

  constructor: (pairindId, promise, client) ->
    @pairingId = pairindId
    @_client = client
    @_currentState = ledger.m2fa.PairingRequest.States.WAITING

    promise.then(
      (result) ->
        l result
      ,
      (err) ->
        e err
      ,
      (progress) =>
        switch progress
          when 'pubKeyReceived'
            return _failure(ledger.m2fa.PairingRequest.Errors.InconsistentState) if @_currentState isnt ledger.m2fa.PairingRequest.States.WAITING
            @_currentState = ledger.m2fa.PairingRequest.States.CHALLENGING
            @emit 'join'
          when 'challengeReceived'
            return _failure(ledger.m2fa.PairingRequest.Errors.InconsistentState) if @_currentState isnt ledger.m2fa.PairingRequest.States.CHALLENGING
            @_currentState = ledger.m2fa.PairingRequest.States.FINISHING
            @emit 'answer'
          when 'secureScreenDisconnect'
            @_failure(ledger.m2fa.PairingRequest.Errors.ClientCancelled) if @_currentState isnt ledger.m2fa.PairingRequest.States.WAITING
          when 'sendChallenge' then @emit 'challenge'
    ).done()
    @_client.on 'm2fa.disconnect'
    @_promise = promise

  onComplete: (cb) -> @_onComplete = cb

  cancel: () ->
    @_promise = null
    @_client.stopIfNeccessary()
    @_onComplete = null
    @emit 'cancel'

  _failure: (reason) ->
    @_currentState = ledger.m2fa.PairingRequest.States.DEAD
    @_onComplete.fail(reason)

  _success: () ->
    @_currentState = ledger.m2fa.PairingRequest.States.DEAD
    @_onComplete.success()