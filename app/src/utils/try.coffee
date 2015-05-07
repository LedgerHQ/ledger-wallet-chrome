
###
  The TryResult type represents a computation that may either result in an exception, or return a successfully computed value.
###
class TryResult

  constructor: (func) ->
    @_deffered = Q.defer()
    try
      @_value = do func
      @_deffered.resolve(@_value)
    catch er
      if er instanceof Error
        @_error = er
      else
        @_error = new Error(er)
      @_deffered.reject(er)

  getError: () -> @_error
  getValue: () -> @_value
  isFailure: -> if @_error? then yes else no
  isSuccess: -> not @isFailure()

  then: (func) -> @promise().then(func)
  fail: (func) -> @promise().fail(func)
  promise: () -> @_deffered.promise

  printError: -> @fail => e @_error

###
  Executes the function passed in parameter. Try returns a {TryResult} which represents the computation of the function that
  may either result in an exception or return a value. This allows to handle errors in a functional manner.

  @param [Function] func A function that may failed
  @return [TryResult] The wrapped computed value or error
###
@Try = (func) -> new TryResult(func)
