
@ledger.m2fa ?= {}

# Wrapper around the transaction API.
# @event complete Called when completed
# @event error Called when a error occured
# @event accepted Called once a client has accepted to handle a transaction request
# @event leave Called once a client has accepted a request and leave the room after
class @ledger.m2fa.TransactionValidationRequest extends @EventEmitter

  @errors:
    TransactionCancelled: "The transaction has been cancelled by the secure screen"
    InvalidResult: "The secure screen sent back an invalid pin"

  constructor: (clients, promise, tx, screen) ->
    @_completion = new CompletionClosure
    @_clients = clients
    promise
    .then (result) =>
      if result?
        @_completion.success(result)
        @emit "complete", result
      else
        @_completion.fail(ledger.m2fa.TransactionValidationRequest.errors.InvalidResult)
        @emit "error"
    .fail (error) =>
      switch error
        when 'cancelled'
          @_completion.fail(ledger.m2fa.TransactionValidationRequest.errors.TransactionCancelled)
          @emit "error"
    .progress (progress) =>
      switch progress
        when 'accepted' then @emit 'accepted'
        when 'disconnect' then @emit 'leave'
    .done()

  cancel: () ->
    @_completion.onComplete _.noop
    @_completion.fail 'Operation cancelled'
    for client in @_clients
      do client?.off
      do client?.stopIfNeccessary
    @_clients = []

  onComplete: (cb) -> @_completion.onComplete cb



