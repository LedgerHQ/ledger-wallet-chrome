
_.mixin

  lock: (thisArg, functionNames) ->
    calls = []
    functions = {}
    lock = on
    unlock = ->
      return unless lock
      lock = off
      for call in calls
        call.deferred.resolve(functions[call.functionName].apply(thisArg, call.arguments))
      return
    for functionName in functionNames
      func = thisArg[functionName]
      functions[functionName] = func
      do (func, functionName) ->
        thisArg[functionName] = ->
          if lock
            deferred = ledger.defer()
            calls.push functionName: functionName, arguments: arguments, deferred: deferred
            deferred.promise
          else
            functions[functionName].apply(thisArg, arguments)
    unlock