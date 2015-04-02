@ledger.utils ?= {}

###
  Utility class for dealing with logs
###
class @ledger.utils.Logger

  # Logger's constructor
  # @param [Boolean] active or not the Logger
  constructor: (tag, @_active) ->
    @_tag = tag
    @_mode = if window.ledger.isDev then "debug" else "release"
    @store = @constructor.store()

  # Sets the active state
  # @param [Boolean] active or not the logger.
  setActive: (active) -> @_active = active

  # Gets the current active state.
  # @return [Boolean] The current enabled flag.
  isActive: -> @_active

  # Clear logs from entries older than 24h
  clear: ->
    self = @
    @store.keys(
      (keys) ->
        now = new Date().getTime();
        self.store.remove key for key in keys when (now - key > 86400000) # 86400000 => 24h
    )

  # Log a debug message
  # @param [String] msg Message to log.
  debug: (msg) ->
    if @_active
      @_storeLog(msg, "DEBUG")
      if(@_mode == "debug")
        console.debug(msg)

  # Log an info
  # @param [String] msg Message to log.
  info: (msg) ->
    if @_active
      @_storeLog(msg, "INFO")
      if(@_mode == "debug")
        console.info(msg)

  # Log a warning
  # @param [String] msg Message to log.
  warn: (msg) ->
    if @_active
      @_storeLog(msg, "WARN")
      if(@_mode == "debug")
        console.warn(msg)

  # Log an error
  # @param [String] msg Message to log.
  error: (msg) ->
    if @_active
      @_storeLog(msg, "ERROR")
      if(@_mode == "debug")
        console.error(msg)

  # Retreive saved logs
  # @param [Function] cb A callback invoked once we get the logs as an array
  logs: (cb) -> @constructor.logs()

  # Save a log in chrome local storage
  # @private
  # @param [String] msg Message to log.
  # @param [String] msgType Log level.
  _storeLog: (msg, msgType) ->
      now = new Date()
      log = {}
      log[now.getTime()] = date: now.toUTCString(), type: msgType, msg: msg, tag: @_tag
      @clear()
      @store.set(log)

  @store: ->
    unless @_store?
      @_store = new ledger.storage.ChromeStore("logs")
    @_store

  @logs: (cb) ->
    completion = new CompletionClosure(cb)
    @store().keys (keys) =>
      @store().get keys, (items) => completion.success(_.values(items))
    completion.readonly()

  @getLoggerByTag: (tag) ->
    @_loggers ?= {}
    unless @_logger[tag]?
      @_logger[tag] = new @(tag)
    @_logger[tag]


ledger.utils.logger = new ledger.utils.Logger("DeprecatedLogger", true)