ledger.tasks ?= {}

class ledger.tasks.Task extends EventEmitter

  @RUNNING_TASKS: {}

  constructor: (taskId) ->
    @taskId = taskId

  start: () ->
    throw "A task with id '#{@taskId}' is already started" if @isRunning()
    ledger.tasks.Task.RUNNING_TASKS[@taskId] = @
    @emit 'start', @
    do @onStart

  startIfNeccessary: () ->
    do @start unless @isRunning()

  stop: () ->
    throw "The task '#{@taskId}' is not running" unless @isRunning()
    delete ledger.tasks.Task.RUNNING_TASKS[@taskId]
    do @onStop
    @emit 'stop', @

  isRunning: () -> ledger.tasks.Task.RUNNING_TASKS[@taskId]?

  onStart: () ->

  onStop: () ->

  @getTask: (taskId) -> ledger.tasks.Task.RUNNING_TASKS[taskId]

  @stopAllRunningTasks: () ->
    for id, task of ledger.tasks.Task.RUNNING_TASKS
      task.stop()
    ledger.tasks.Task.RUNNING_TASKS = {}

