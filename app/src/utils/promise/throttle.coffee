ledger.utils ?= {}
ledger.utils.promise = {} unless ledger.utils.promise?

_.extend ledger.utils.promise,

  throttle: (func, wait) ->
    deferred = null
    args = undefined
    (a...) ->
      args = a
      return deferred.promise if deferred? and !deferred.promise.isFulfilled()
      deferred = ledger.defer()
      setTimeout ->
        deferred.resolve(func(args...))
      , wait
      deferred.promise