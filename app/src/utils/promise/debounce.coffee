ledger.utils ?= {}
ledger.utils.promise = {} unless ledger.utils.promise?

_.extend ledger.utils.promise,

  debounce: (func, wait) ->
    deferred = null
    timeout = null
    args = undefined
    onTimeoutExpired = -> deferred.resolve(func(args...))
    (a...) ->
      args = a
      if deferred? and !deferred.isFulfilled()
        clearTimeout(timeout)
      else
        deferred = ledger.defer()
      timeout = setTimeout(onTimeoutExpired, wait)
      deferred.promise