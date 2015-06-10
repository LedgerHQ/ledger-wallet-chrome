ledger.utils ?= {}
ledger.utils.promise = {} unless ledger.utils.promise?

_.extend ledger.utils.promise,

  throttle: (func, wait, {immediate}) ->
    deferred = null
    args = undefined
    immediate ?= no
    (a...) ->
      args = a
      return deferred.promise if deferred? and !deferred.promise.isFulfilled()
      deferred = ledger.defer()
      deferred.resolve(func(args...)) if immediate
      setTimeout ->
        deferred.resolve(func(args...)) unless immediate
        deferred = null
      , wait
      deferred.promise