
###
  A helper class for defining a node like callback. A completion closure is a callback holder that can be either successful
  or failed. If a result is set and no function is defined, the CompletionClosure will keep the result until a callback function
  is submitted. Callback function are defining as node callback

  @example Simple case
    completion = new CompletionClosure()
    completion.success("A value")
    completion.onComplete (result, err) ->
      console.log(result)

###
class @CompletionClosure

  constructor: () ->
    @_isSuccessful = no
    @_isFailed = no
    @_complete = [null, null]

  ###
    Completes the closure with success. This method will call the onComplete function if possible or keep the result until
    a callback is submitted.

    @param [Any] value A value to complete the closure
    @return [CompletionClosure] self
    @throw If the closure is already completed
  ###
  success: (value) ->
    throw 'CompletionClosure already completed' if @isCompleted()
    @_isSuccessful = yes
    @_complete = [value, null]
    @_tryNotify()
    @

  ###
    Completes the closure with an error. This method will call the onComplete function if possible or keep the error until
    a callback is submitted.

    @param [Any] error A error to failed the closure
    @return [CompletionClosure] self
    @throw If the closure is already completed
  ###
  fail: (error) ->
    throw 'CompletionClosure already completed' if @isCompleted()
    @_isFailed = yes
    @_complete = [null, error]
    @_tryNotify()
    @

  ###
    Sets the callback closure. If the CompletionClosure is already completed and no callback has been submitted yet,
    the method will directly call the function.

    @example Function prototype
      (result, err) ->

    @param [Function] func A function declared as a NodeJS callback
    @return [CompletionClosure] self
  ###
  onComplete: (func) ->
    @_func = func
    @_tryNotify()

  ###
    Returns 'yes' if completed else 'no'
    @return [Boolean]
  ###
  isCompleted: () -> !(!@_isSuccessful and !@_isFailed)
  isSuccessful: () -> @_isSuccessful
  isFailed: () -> @_isFailed

  _tryNotify: () ->
    return unless @isCompleted()
    [result, error] = @_complete
    if @_func? and (result? or error?)
      @_complete = []
      @_func(result, error)