
@ledger.m2fa ?= {}

# Wrapper around the transaction API.
# @event complete Called when completed
class @ledger.m2fa.TransactionValidationRequest extends @EventEmitter

  constructor: (clients, promise) ->
    @_completion = new CompletionClosure
    @_clients = clients
    promise.then (result) =>
      @_onComplete.success(result)
    , (error) =>
      e error
      @_onComplete.fail(error)
    , (progress) =>
      @emit progress
    .done()

  cancel: () ->
    @_completion.onComplete _.noop
    @_completion.fail 'Operation cancelled'
    for client in @_clients
      do client?.off
      do client?.stopIfNeccessary
    @_clients = []

  onComplete: (cb) -> @_completion.onComplete cb



