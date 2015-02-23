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
      l "Trying to stop  #{@taskId}", @, ledger.tasks.Task.RUNNING_TASKS
      return if not @isRunning()
      ledger.tasks.Task.RUNNING_TASKS = _.omit(ledger.tasks.Task.RUNNING_TASKS, @taskId)
      l "Stopping #{@taskId}"
      do @onStop
      @emit 'stop', @
    @

  stopIfNeccessary: () -> @stop(yes) if @isRunning()

  isRunning: () -> if ledger.tasks.Task.RUNNING_TASKS[@taskId]? then yes else no

  onStart: () ->

  onStop: () ->

  @getTask: (taskId) -> ledger.tasks.Task.RUNNING_TASKS[taskId]

  @stopAllRunningTasks: () ->
    tasks = _.values(ledger.tasks.Task.RUNNING_TASKS)
    l "Stopping all", ledger.tasks.Task.RUNNING_TASKS
    for task in tasks
      task.stopIfNeccessary()

  @resetAllSingletonTasks: () ->
    for name, task of ledger.tasks when task?.reset? and _.isFunction(task.reset)
      task.reset()

