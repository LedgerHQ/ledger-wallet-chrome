
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

  ###
    Wraps a node-like asynchronous method in a {CompletionClosure}. This method is useful if you need promise chaining.

    @example Case without {CompletionClosure.call}
      asyncFunc = (arg1, callback) ->
        ... do something ...

      asyncFunc 'oiseau', (result, error) ->
        ... do something ...

    @example Case with {CompletionClosure.call}
      asyncFunc = (arg1, callback) ->
        ... do something ...

      CompletionClosure.call(asyncFunc, null, 'oiseau').promise()
        .then (result) ->
          ... do something ...
        .fail () ->
          ... do something ...

    @param [Function] func The function to call
    @param [Object] self The calling this object
    @param [Object*] args Method args
    @return [CompletionClosure] The closure
  ###
  @defer: (func, self, args...) ->
    closure = new @
    onComplete = (result, error) -> closure.complete(result, error)
    args.push onComplete
    func.apply(self, args)
    closure

  constructor: (callback = null) ->
    @_isSuccessful = no
    @_isFailed = no
    @_isJqFulfilled = no
    @_isQFulfilled = no
    @_complete = [null, null]
    @onComplete callback if callback?

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
    @_tryFulfill()
    @

  ###
    Completes the closure with an error. This method will call the onComplete function if possible or keep the error until
    a callback is submitted.

    @param [Any] error An error to failed the closure
    @return [CompletionClosure] self
    @throw If the closure is already completed
  ###
  fail: (error) ->
    throw 'CompletionClosure already completed' if @isCompleted()
    @_isFailed = yes
    @_complete = [null, error]
    @_tryNotify()
    @_tryFulfill()
    @

  ###
    Completes the closure either by a success or an error. If both error and result are null, the closure will be failed
    with an 'Unknown Error'.

    @param [Any] value A value to complete the closure (may be null)
    @param [Any] error An error to failed the closure (may be null)
    @return [CompletionClosure] self
    @throw If the closure is already completed
  ###
  complete: (value, error) ->
    unless error?
      @success(value)
    else
      @fail(error)
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
    @_tryFulfill()

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

  _tryFulfill: () ->
    return unless @isCompleted()
    [result, error] = @_complete
    if not @_isQFulfilled and @_qDefferedObject?
      @_qDefferedObject.fulfill(result) if @isSuccessful()
      @_qDefferedObject?.reject(error) if @isFailed()
      @_isQFulfilled = yes
    if not @_isJqFulfilled and @_jqDefferedObject?
      @_jqDefferedObject.resolve(result) if @isSuccessful()
      @_jqDefferedObject.reject(error) if @isFailed()
      @_isJqFulfilled = yes

  _qDeffered: () ->
    unless @_qDeferredObject?
      @_qDeferredObject = Q.defer()
      @_tryFulfill()
    @_qDeferredObject

  _jqDeffered: () ->
    unless @_jqDefferedObject?
      @_jqDefferedObject = jQuery.Deferred()
      @_tryFulfill()
    @_jqDefferedObject

  ###
    Returns a readonly version of the closure

    @return [Object] A readonly version of the closure
  ###
  readonly: () ->
    c = new CompletionClosure()
    delete c.success
    delete c.fail
    delete c.complete
    for key, value of c when _(value).isFunction()
      c[key] = @[key].bind(@)
    c

  ###
    Returns a Q promise

    @return [Q.Promise] A Q promise
  ###
  q: () -> @_qDeffered().promise

  ###
    Alias for q method

    @see CompletionClosure#q
  ###
  promise: () -> @q()

  ###
    Returns jQuery promise
    @return [jQuery.Promise] A jQuery promise
  ###
  jq: () -> @_jqDeffered().promise()

  ###
    Alias for jq method

    @see CompletionClosure#jq
  ###
  jpromise: () -> @jq()