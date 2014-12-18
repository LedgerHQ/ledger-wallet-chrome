ledger.tasks ?= {}

class ledger.tasks.Task extends EventEmitter

  @RUNNING_TASKS: {}

  constructor: (taskId) ->
    @taskId = taskId

  start: (safe = no) ->
    _.defer =>
      throw "A task with id '#{@taskId}' is already started" if @isRunning() and not safe
      return if @isRunning() and safe
      ledger.tasks.Task.RUNNING_TASKS[@taskId] = @
      @emit 'start', @
      do @onStart
    @

  startIfNeccessary: () ->
    @start(yes) unless @isRunning()
    @

  stop: (safe = no) ->
    _.defer =>
      throw "The task '#{@taskId}' is not running" if not @isRunning() and not safe
      return if not @isRunning() and safe
      ledger.tasks.Task.RUNNING_TASKS = _.omit(ledger.tasks.Task.RUNNING_TASKS, @taskId)
      do @onStop
      @emit 'stop', @
    @

  stopIfNeccessary: () -> @stop(yes) if @isRunning()

  isRunning: () -> ledger.tasks.Task.RUNNING_TASKS[@taskId]?

  onStart: () ->

  onStop: () ->

  @getTask: (taskId) -> ledger.tasks.Task.RUNNING_TASKS[taskId]

  @stopAllRunningTasks: () ->
    for id, task of ledger.tasks.Task.RUNNING_TASKS
      task.stopIfNeccessary()
    ledger.tasks.Task.RUNNING_TASKS = {}

  @resetAllSingletonTasks: () ->
    for name, task of ledger.tasks when task?.reset? and _.isFunction(task.reset)
      task.reset()

