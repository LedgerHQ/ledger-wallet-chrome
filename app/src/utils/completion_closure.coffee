
###
  A helper class for defining a callback. A completion closure is a callback holder that can be either successful
  or failed. If a result is set and no function is defined, the CompletionClosure will keep the result until a callback function
  is submitted.

  CompletionClosure can also create a copy of themselves (with {CompletionClosure#readonly}) which cannot complete the closure.
  This is handy if you need to return the closure and still want to be the only to have control over the completion.

  It can also be chained with Q.Promise or jQuery.Promise.

  @example Simple case
    completion = new CompletionClosure()
    completion.success("A value")
    completion.onComplete (result, err) ->
      console.log(result)

  @example With Promises
    completion = new CompletionClosure()
    completion.success("A value")
    completion.then (result) ->
      console.log(result)

  @example Create a function that is compatible with both promise and callback

    asyncFunc = (param, callback = null) ->
      completion = new CompletionClosure(callback)
      doSomethingAsync ->
        completion.success("A value")
      completion.readonly()

    # asyncFunc can be used either like this...
    asyncFunc "a param", (result, error) ->
      ... Do something ...

    # or like this
    asyncFunc "a param"
      .then (result) ->
        ... Do something ...
      .fail (error) ->
        ... Do something ...
      .done()

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
    return

  ###
    Completes the closure with an error. This method will call the onComplete function if possible or keep the error until
    a callback is submitted.

    @param [Any] error An error to failed the closure
    @return [CompletionClosure] self
    @throw If the closure is already completed
  ###
  failure: (error) ->
    throw 'CompletionClosure already completed' if @isCompleted()
    @_isFailed = yes
    @_complete = [null, error]
    @_tryNotify()
    @_tryFulfill()
    return

  ###
    Completes the closure with a standard error. This method will call the onComplete function if possible or keep the error until
    a callback is submitted.

    @param [Any] error An error to failed the closure
    @return [CompletionClosure] self
    @throw If the closure is already completed
  ###
  failWithStandardError: (errorCode) -> @failure(new ledger.StandardError(errorCode))

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

  ###
    Sets the callback closure. If the CompletionClosure is already completed and no callback has been submitted yet,
    the method will directly call the function.

    @example Function prototype
      (result, err) ->

    @param [Function] func A function declared as follow '(result, err) ->'
    @return [CompletionClosure] self
  ###
  onComplete: (func) ->
    @_func = func
    @_tryNotify()
    @_tryFulfill()

  ###
    @overload
      @param [CompletionClosure] defer
      @return [CompletionClosure] self

    @overload
      @param [Q.defer] defer
      @return [CompletionClosure] self
  ###
  thenForward: (defer) ->
    deferType = typeof defer
    if deferType == 'object' && defer instanceof CompletionClosure
      @then( (=> defer.success.apply(defer, arguments)), (=> defer.failure.apply(defer, arguments)) )
    else if deferType == 'object' && defer instanceof Q.defer
      @then( (=> defer.resolve.apply(defer, arguments)), (=> defer.reject.apply(defer, arguments)) )
    else
      throw new ArgumentError(if promiseType == 'object' then promise.constructor.name else promiseType)

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
    if @_func?
      @_complete = []
      @_func(result, error)

  _tryFulfill: () ->
    return unless @isCompleted()
    [result, error] = @_complete
    if not @_isQFulfilled and @_qDeferredObject?
      @_qDeferredObject.resolve(result) if @isSuccessful()
      @_qDeferredObject?.reject(error) if @isFailed()
      @_isQFulfilled = yes
    if not @_isJqFulfilled and @_jqDeferredObject?
      @_jqDeferredObject.resolve(result) if @isSuccessful()
      @_jqDeferredObject.reject(error) if @isFailed()
      @_isJqFulfilled = yes

  _qDeffered: () ->
    unless @_qDeferredObject?
      @_qDeferredObject = Q.defer()
      @_tryFulfill()
    @_qDeferredObject

  _jqDeffered: () ->
    unless @_jqDeferredObject?
      @_jqDeferredObject = jQuery.Deferred()
      @_tryFulfill()
    @_jqDeferredObject

  ###
    Returns a readonly version of the closure

    @return [Object] A readonly version of the closure
  ###
  readonly: () ->
    c = new CompletionClosure()
    delete c.success
    delete c.failure
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

  ###
    Shorthand for completionClosure.q().then()

    @return [Q.Promise]
  ###
  then: (fulfilled, rejected = undefined, progressed = undefined) -> @q().then(fulfilled, rejected, progressed)

  ###
    Shorthand for completionClosure.q().fail()

    @return [Q.Promise]
  ###
  fail: (rejected) -> @q().fail(rejected)

  ###
    Shorthand for completionClosure.q().progress()

    @return [Q.Promise]
  ###
  progress: (progressed) -> @q().progress(progressed)