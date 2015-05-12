@ledger ?= {}
@ledger.utils ?= {}

###
@exemple Usage
text = ""
queue = new ledger.utils.PromiseQueue()

queue.enqueue ->
  d = Q.defer()
  setTimeout ->
    text += "Hello"
    d.resolve()
  , 5000
  d.promise

queue.enqueue ->
  d = Q.defer()
  setTimeout ->
    text += " world"
    d.resolve()
  , 1000
  d.promise

queue.enqueue ->
  d = Q.defer()
  setTimeout ->
    text += " !"
    d.resolve()
  , 3000
  d.promise

queue.enqueue ->
  console.log(text) # => "Hello world !"
  Q()
###
class @ledger.utils.PromiseQueue extends @EventEmitter
  PromiseQueue = @

  @TIMOUT_DELAY: 60 * 1000 # 60s

  constructor: (@name) ->
    @brakName = "[#{@name}]" if @name
    @_taskRunning = false
    @_queue = []

  isRunning: -> @_taskRunning
  length: -> @_queue.length

  ###
  @overload enqueue: (task) ->
    @param [Function] task
    @return [Q.Promise]

  @overload enqueue: (taskId, task) ->
    @param [Number, String] taskId
    @param [Function] task
    @return [Q.Promise]
  ###
  enqueue: (taskId, task) ->
    [taskId, task] = [Math.round(Math.random() * 1000), taskId] if ! task && typeof taskId == 'function'
    defer = ledger.defer()
    taskWrapper = =>
      @emit 'task:starting', taskId
      try
        # TODO: use defer.promise.isFilfilled instead of done, but fail randomly sometimes.
        timer = @_setTimeout(taskId, defer)
        task().finally( =>
          clearTimeout(timer)
          @emit 'task:done', taskId
          @_taskDone(); return
        ).then( (args...) -> defer.resolve(args...); return
        ).progress( (args...) =>
          clearTimeout(timer)
          timer = @_setTimeout(taskId, defer)
          defer.notify(args...); return
        ).catch( (args...) -> defer.reject(args...); return
        ).done()
      catch err
        console.error("PromiseQueue#{@brakName} Fail to exec task #{taskId} :", err)
        defer.reject(err)
    if @_taskRunning
      @_queue.push([taskId, taskWrapper])
      @emit 'queue:pushed', taskId
    else
      @_taskRunning = true
      _.defer -> taskWrapper()
    return defer.promise

  _taskDone: ->
    if @_queue.length > 0
      [taskId, task] = @_queue.shift()
      @emit 'queue:shifted', taskId
      task()
    else
      @_taskRunning = false
      @emit 'queue:empty'

  _setTimeout: (taskId, defer) ->
    setTimeout (=> @_timeout(taskId, defer)), PromiseQueue.TIMOUT_DELAY

  _timeout: (taskId, defer) ->
    return if defer.promise.isFulfilled()
    if @_queue.length > 0
      console.warn("PromiseQueue#{@brakName} Timeout for task #{taskId}. Call next task.")
      setTimeout (=> @_timeout(taskId, defer)), PromiseQueue.TIMOUT_DELAY
      @_taskDone()
    else
      msg = "PromiseQueue#{@brakName} Timeout for task #{taskId}. No task to call."
      console.error(msg)
      defer.rejectWithError(ledger.errors.TimeoutError, msg)