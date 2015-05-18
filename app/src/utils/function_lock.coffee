
_.mixin

  lock: (thisArg, functionNames) ->
    calls = []
    functions = {}
    lock = on
    unlock = ->
      return unless lock
      lock = off
      for call in calls
        functions[call.functionName].apply thisArg, call.arguments
      return
    for functionName in functionNames
      func = thisArg[functionName]
      functions[functionName] = func
      do (func, functionName) ->
        thisArg[functionName] = ->
          if lock
            calls.push functionName: functionName, arguments: arguments
          else
            functions[functionName].apply(thisArg, arguments)
          return
    unlock