
@ledger.m2fa ?= {}

# Wrapper around the pairing API. This class defines the followings events:
#   - 'complete'
#   - 'cancel'
#   - 'joined'
#   - 'leave'
class PairingRequest extends @EventEmitter

  constructor: (pairingTuple) ->
    [@_pairingId, promise, @_client] = pairingTuple
    promise.then(
      (result) ->
        l result
      ,
      (err) ->
        l err
      ,
      (progress) ->
        l progress
    ).done()
    @_promise = promise

  cancel: () ->
    @_promise = null
    @_client.stopIfNeccessary()
    @_onComplete = null
    @_onCancel?()