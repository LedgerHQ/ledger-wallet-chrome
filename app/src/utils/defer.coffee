@legder || = {}

@ledger.defer = (arg=undefined, args...) ->
  isCallback = typeof arg == 'function' && args.length == 0
  callback = arg if isCallback
  if isCallback
    defer = Q.defer()
  else
    defer = Q.defer(arg, args...)

  # Prototype
  defer.rejectWithError = (args...) -> ledger.errors.new(args...)
  defer.onFulfilled = (callback) ->
    @promise
    .then (result) -> callback(if result != undefined then result else true)
    .fail (reason) -> callback(false, reason)
  defer.oldResolve = defer.resolve
  defer.oldReject = defer.reject
  defer.resolve = (args...) -> @oldResolve(args...); return @
  defer.reject = (args...) -> @oldReject(args...); return @

  # CompletionClosure legacy
  defer.complete = (value, error) ->
    if error?
      @reject(error)
    else
      @resolve(value)
  defer.onComplete = defer.onFulfilled

  defer.onFulfilled(callback) if isCallback

  return defer
