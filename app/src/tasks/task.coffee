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
      @logger().info "Starting task #{@taskId}"
      do @onStart
    @

  startIfNeccessary: () ->
    @start(yes) unless @isRunning()
    @

  stop: (safe = no) ->
    _.defer =>
      throw "The task '#{@taskId}' is not running" if not @isRunning() and not safe
      return if not @isRunning()
      ledger.tasks.Task.RUNNING_TASKS = _.omit(ledger.tasks.Task.RUNNING_TASKS, @taskId)
      @logger().info "Stopping task #{@taskId}"
      do @onStop
      @emit 'stop', @
    @

  logger: -> @_logger ||= ledger.utils.Logger.getLoggerByTag(@constructor.name)

  stopIfNeccessary: () -> @stop(yes) if @isRunning()

  isRunning: () -> if ledger.tasks.Task.RUNNING_TASKS[@taskId]? then yes else no

  onStart: () ->

  onStop: () ->

  @getTask: (taskId) -> ledger.tasks.Task.RUNNING_TASKS[taskId]

  @stopAllRunningTasks: () ->
    tasks = _.values(ledger.tasks.Task.RUNNING_TASKS)
    ledger.utils.Logger.getLoggerByTag('Tasks').info "Stopping all", ledger.tasks.Task.RUNNING_TASKS
    for task in tasks
      task.stopIfNeccessary()

  @resetAllSingletonTasks: () ->
    for name, task of ledger.tasks when task?.reset? and _.isFunction(task.reset)
      task.reset()

