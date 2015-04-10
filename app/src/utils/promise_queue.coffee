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
  constructor: ->
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
        promise = task()
        defer.resolve(promise)
      catch err
        defer.reject(err)
      defer.promise.finally =>
        @emit 'task:done', taskId
        @_taskDone()
      promise.done()
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
