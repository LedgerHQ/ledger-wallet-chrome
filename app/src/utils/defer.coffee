@ledger ?= {}

@ledger.defer = (arg=undefined, args...) ->
  isCallback = typeof arg == 'function' && args.length == 0
  callback = arg if isCallback
  if isCallback
    defer = Q.defer()
  else
    defer = Q.defer(arg, args...)

  # Prototype
  defer.rejectWithError = (args...) -> @reject(ledger.errors.new(args...))
  defer.oldResolve = defer.resolve
  defer.oldReject = defer.reject
  defer.resolve = (args...) -> @oldResolve(args...); return @
  defer.reject = (args...) -> @oldReject(args...); return @
  defer.promise.onFulfilled = (callback) ->
    @then( (result) ->
      _.defer -> callback(if result != undefined then result else true)
      return
    ).catch( (reason) ->
      _.defer -> callback(false, reason)
      return
    ).done()

  # CompletionClosure legacy
  defer.complete = (value, error) ->
    if error?
      @reject(error)
    else
      @resolve(value)
  defer.promise.onComplete = defer.promise.onFulfilled
  defer.onComplete = (args...) -> @promise.onComplete(args...)

  defer.promise.onFulfilled callback if isCallback

  return defer

@ledger.delay = (ms) ->
  deferred = ledger.defer();
  setTimeout(deferred.resolve.bind(deferred), ms);
  deferred.promise;


_.mixin

  smartTimeout: (object, timeout, message = 'Timeout operation') ->
    if !_.isFunction(object?.then) and !_.isFunction(object?.fail)
      throw new Error("Smart timeout needs a promise")

    scheduled = null
    d = ledger.defer()

    onTimeout = -> d.reject(new Error(message))
    scheduleTimeout = ->
      clearTimeout(scheduled) if scheduled?
      scheduled = setTimeout(onTimeout, timeout)
    onWindowResize = -> scheduleTimeout()

    scheduleTimeout()
    window.addEventListener('resize', onWindowResize)
    object.then (results...) ->
      l "Smart results ", results
      d.resolve(results...)
    .fail (errors...) ->
      d.reject(errors...)
    d.promise.fin ->
      window.removeEventListener('resize', onWindowResize)
      clearTimeout(scheduled) if scheduled?
    d.promise