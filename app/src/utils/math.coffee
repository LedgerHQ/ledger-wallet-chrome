
ledger.math ||= {}

fibonacciCache = [0, 1]

_.extend ledger.math,

  fibonacci: (n) ->
    return 0 if n < 0
    return fibonacciCache[n] if n < fibonacciCache.length
    for pos in [fibonacciCache.length - 1...n]
      fibonacciCache.push fibonacciCache[pos - 1] + fibonacciCache[pos]
    fibonacciCache[n]

