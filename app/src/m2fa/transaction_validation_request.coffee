
@ledger.m2fa ?= {}

Errors = ledger.errors

# Wrapper around the transaction API.
# @event complete Called when completed
# @event error Called when a error occured
# @event accepted Called once a client has accepted to handle a transaction request
# @event leave Called once a client has accepted a request and leave the room after
class @ledger.m2fa.TransactionValidationRequest extends @EventEmitter

  constructor: (clients, promise) ->
    @_defer = ledger.defer (args...) => @_onComplete?(args...)
    @_clients = clients
    promise
    .progress (progress) =>
      switch progress
        when 'accepted' then @emit 'accepted'
        when 'disconnect' then @emit 'leave'
    .then (result) =>
      if result?
        @_defer.resolve(result)
        @emit "complete", result
      else
        @_defer.reject(Errors.InvalidResult)
        @emit "error"
    .fail (error) =>
      switch error
        when 'cancelled'
          @_defer.reject(Errors.TransactionCancelled)
          @emit "error"
        else
          console.error("TransactionValidationRequest fail:", error)
    .done()

  cancel: () ->
    do @off
    unless @_defer.promise.isFulfilled()
      @_onComplete = undefined
      @_defer.reject 'Operation cancelled'
    for client in @_clients
      do client?.off
      do client?.stopIfNeccessary
    @_clients = []

  onComplete: (cb) -> @_onComplete = cb

