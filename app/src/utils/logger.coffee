@ledger ?= {}
@ledger.utils ?= {}

Levels =
  NONE: 0
  RAW: 1
  FATAL: 2
  ERROR: 3
  WARN: 4
  BAD: 5
  GOOD: 6
  INFO: 7
  VERB: 8
  DEBUG: 9
  TRACE: 10
  ALL: 12

###
  Utility class for dealing with logs
###
class @ledger.utils.Logger
  @Levels: Levels

  @_privateMode: off
  @_loggers: {}

  # Return storage instance if initialized or undefined.
  # @return [ledger.storage.ChromeStore, undefined]
  @store: ->
    if ledger.storage.logs? then ledger.storage.logs else @_store ?= new ledger.storage.ChromeStore("logs")

#################################
# Class methods
#################################
  
  # @return [Q.Promise]
  @logs: (cb) -> @_getLogs(@store())

  @publicLogs: (cb) -> @_getLogs(@_store ?= new ledger.storage.ChromeStore("logs"), cb)

  @privateLogs: (cb) ->
    return cb?([]) unless ledger.storage.logs?
    @_getLogs(ledger.storage.logs, cb)

  @_getLogs: (store, cb) ->
    d = ledger.defer(cb)
    store.keys (keys) =>
      store.get keys, (items) => d.resolve(_.values(items))
    d.promise

  # @return [legder.utils.Logger]
  @getLoggerByTag: (tag) ->
    @_loggers[tag] ?= new @(tag)

  # Set all loggers level
  @_setGlobalLoggersLevel: (level) -> logger.setLevel(level) for name, logger of @_loggers when logger.useGlobalSettings
  @setGlobalLoggersLevel: (level) -> @_setGlobalLoggersLevel(level)

  @setGlobalLoggersPersistentLogsEnabled: (enable) -> logger.setPersistentLogsEnabled(enable) for name, logger of @_loggers when logger.useGlobalSettings

  @getGlobalLoggersLevel: ->
    if ledger.preferences?.instance?
      if ledger.preferences.instance.isLogActive() then ledger.config.defaultLoggingLevel.Connected.Enabled else ledger.config.defaultLoggingLevel.Connected.Disabled
    else if ledger.config?.defaultLoggingLevel?
      if ledger.config.enableLogging then ledger.config.defaultLoggingLevel.Disconnected.Enabled else ledger.config.defaultLoggingLevel.Disconnected.Disabled
    else
      Levels.NONE

  @updateGlobalLoggersLevel: -> @_setGlobalLoggersLevel(@getGlobalLoggersLevel())

  @exportLogsToCsv: (callback = undefined) ->
    now = new Date()
    csv = new ledger.utils.CsvExporter("ledger_wallet_logs_#{now.getFullYear()}#{_.str.lpad(now.getMonth() + 1, 2, '0')}#{now.getDate()}")
    @publicLogs (publicLogs) =>
      @privateLogs (privateLogs) =>
        csv.setContent _.sortBy((publicLogs || []).concat(privateLogs || []), (log) -> log.date)
        csv.save(callback)

  @exportLogsToBlob: (callback = undefined) ->
    now = new Date()
    suggestedName = "ledger_wallet_logs_#{now.getFullYear()}#{_.str.lpad(now.getMonth() + 1, 2, '0')}#{now.getDate()}"
    csv = new ledger.utils.CsvExporter(suggestedName)
    @publicLogs (publicLogs) =>
      @privateLogs (privateLogs) =>
        csv.setContent _.sortBy((publicLogs || []).concat(privateLogs || []), (log) -> log.date)
        callback?(name: suggestedName, blob: csv.blob())

  @exportLogsToZip: (callback = undefined) ->
    now = new Date()
    suggestedName = "ledger_wallet_logs_#{now.getFullYear()}#{_.str.lpad(now.getMonth() + 1, 2, '0')}#{now.getDate()}"
    csv = new ledger.utils.CsvExporter(suggestedName)
    @publicLogs (publicLogs) =>
      @privateLogs (privateLogs) =>
        csv.setContent _.sortBy((publicLogs || []).concat(privateLogs || []), (log) -> log.date)
        csv.zip (zip) =>
          callback?(name: suggestedName, zip: zip)

  @exportLogsWithLink: (callback = undefined) ->
    now = new Date()
    suggestedName = "ledger_wallet_logs_#{now.getFullYear()}#{_.str.lpad(now.getMonth() + 1, 2, '0')}#{now.getDate()}"
    csv = new ledger.utils.CsvExporter(suggestedName)
    @publicLogs (publicLogs) =>
      @privateLogs (privateLogs) =>
        csv.setContent _.sortBy((publicLogs || []).concat(privateLogs || []), (log) -> log.date)
        callback?(name: suggestedName, url: csv.url())

  @downloadLogsWithLink: ->
    @exportLogsWithLink (data) ->
      pom = document.createElement('a')
      pom.href = data.url
      pom.setAttribute('download', data.name)
      pom.click()

  @setPrivateModeEnabled: (enable) ->
    if enable isnt @_privateMode
      @_privateMode = enable
      @_logStream = if enable then @_createStream() else null

  @isPrivateModeEnabled: -> @_privateMode

  @_createStream: ->
    stream = new Stream()
    stream.on "data", =>
      stream._store ||= ledger.storage.logs
      return unless stream._store?
      logs = stream.read()
      # Insert logs
      data = {}
      for log in logs
        for key, entry of log
          data[key] = entry
      stream._store.set data
      # Clear old
      @_clear(stream.store)
      stream.close() if @_logStream isnt stream
    stream.open()
    stream

#################################
# Instance methods
#################################

  # Logger's constructor
  # @param [String, Number, Boolean] level of the Logger
  constructor: (tag, @level = ledger.utils.Logger.getGlobalLoggersLevel(), @useGlobalSettings = yes) ->
    @_tag = tag
    @level = Levels[@level] if typeof @level == "string"
    @level = Levels.ALL if @level is true
    @level = Levels.NONE if @level is false
    @setPersistentLogsEnabled on
    @constructor._loggers[tag] = this

  setPersistentLogsEnabled: (enable) -> @_areLogsPersistents = enable

  #################################
  # Accessors
  #################################

  # Return Logger class storage if initialized or undefined.
  # @return [ledger.storage.ChromeStore, undefined]
  store: -> @constructor.store()

  isPrivateModeEnabled: -> @constructor.isPrivateModeEnabled()

  # Sets the log level
  # @param [Boolean] active or not the logger.
  setLevel: (level) -> @level = level

  #
  levelName: (level = @level) -> _.invert(Levels)[level]

  # Sets the active state
  # @param [Boolean] active or not the logger.
  setActive: (active) -> @level = if active then Levels.INFO else Levels.NONE

  # Gets the current active state.
  # @return [Boolean] The current enabled flag.
  isActive: -> @level > Levels.NONE

  isFatal: -> @level >= Levels.FATAL
  isError: -> @level >= Levels.ERROR
  isErr: @prototype.isError
  isWarn: -> @level >= Levels.WARN
  isWarning: @prototype.isWarn
  isBad: -> @level >= Levels.BAD
  isGood: -> @level >= Levels.GOOD
  isGood: @prototype.isSuccess
  isInfo: -> @level >= Levels.INFO
  isVerb: -> @level >= Levels.VERB
  isVerbose: @prototype.isVerb
  isDebug: -> @level >= Levels.DEBUG
  isTrace: -> @level >= Levels.TRACE

  #################################
  # Logging methods
  #################################

  fatal: (args...) -> @_log(Levels.FATAL, args...)
  error: (args...) -> @_log(Levels.ERROR, args...)
  err: @prototype.error
  warn: (args...) -> @_log(Levels.WARN, args...)
  warning: @prototype.warn
  bad: (args...) -> @_log(Levels.BAD, args...)
  good: (args...) -> @_log(Levels.GOOD, args...)
  success: @prototype.good
  info: (args...) -> @_log(Levels.INFO, args...)
  verb: (args...) -> @_log(Levels.VERB, args...)
  verbose: @prototype.verb
  debug: (args...) -> @_log(Levels.DEBUG, args...)
  raw: (args...) -> @_log(Levels.RAW, args...)
  trace: (args...) -> @_log(Levels.TRACE, args...)

  #################################
  # Stored Logs
  #################################

  # Clear logs from entries older than 24h
  clear: -> @constructor._clear @store()

  @_clear: (store) ->
    store?.keys (keys) =>
      now = new Date().getTime()
      store.remove(key) for key in keys when (now - key > 86400000) # 86400000ms => 24h

  # Retreive saved logs
  # @param [Function] cb A callback invoked once we get the logs as an array
  # @return [Q.Promise]
  logs: (cb) ->
    @constructor.logs().then (logs) =>
      logs = logs.filter (l) => l.tag is @tag
      cb?(logs)
      logs

  # Save a log in chrome local storage
  # @private
  # @param [String] msg Message to log.
  # @param [String] msgType Log level.
  _storeLog: (msg, msgType) ->
    return unless @_areLogsPersistents
    now = new Date()
    log = {}
    log[now.getTime()] = date: now.toUTCString(), type: msgType,  tag: @_tag, msg: msg
    if @isPrivateModeEnabled()
      @_privateLogStream().write(log)
    else
      @clear()
      @store().set(log)

  #################################
  # Protected. Formatting methods
  #################################

  ###
  Generic log function. Add header with usefull informations + log to console + store in DB.

  @exemple Simple call 
    @_log(Levels.VERB, "Entering in function with args", arg1, arg2)

  @param [Number] level defined in Levels.
  @return undefined
  ###
  _log: (level, args...) ->
    return unless level <= @level
    @_storeLog(@_stringify(args...), @levelName(level))
    if ledger.isDev
      args = (if level != Levels.RAW then [@_header(level)] else []).concat(args)
      @_consolify(level, args...)

  ###
  Add usefull informations like level and timestamp.
  @param [Number] level
  @return String
  ###
  _header: (level, date) ->
    _.str.sprintf('[%s][%s][%s]', @_timestamp(date), @levelName(level), @_tag)

  ###
  @param [Date] date
  @return String
  ###
  _timestamp: (date=new Date()) ->
    _.str.sprintf("%s.%03d", date.toLocaleTimeString(), date.getMilliseconds())

  ###
  Convert correctly arguments into string.
  @return String
  ###
  _stringify: (args...) ->
    formatter = if typeof args[0] is 'string' then ""+args.shift().replace(/%/g,'%%') else ""
    params = for arg in args
      formatter += " %s"
      if (! arg?) || typeof arg == 'string' || typeof arg == 'number' || typeof arg == 'boolean'
        arg
      else if typeof arg == 'object' && (arg instanceof RegExp || arg instanceof Date)
        arg
      else if typeof arg == 'object' && arg instanceof HTMLElement
        "HTMLElement." + arg.tagName
      else # Arrays and Hashs
        try
          JSON.stringify(arg)
        catch err
          "<< stringify error: #{err} >>"
    _.str.sprintf(formatter, params...)

  ###
  Add color depending of level.
  @return undefined
  ###
  _consolify: (level, args...) ->
    args = [].concat(args)

    # Add color
    if typeof args[0] is 'string'
      args[0] = "%c" + args[0].replace(/%/g,'%%')
    else
      args.splice 0, 0, "%c"
    args.splice 1, 0, switch level
      when Levels.FATAL, Levels.ERROR, Levels.BAD then 'color: #f00'
      when Levels.WARN then 'color: #f60'
      when Levels.INFO then 'color: #00f'
      when Levels.GOOD then 'color: #090'
      when Levels.DEBUG then 'color: #444'
      when Levels.TRACE then 'color: #777'
      else 'color: #000'

    # Add arguments catchers to colorify strings
    for arg in args[2..-1]
      args[0] += if typeof arg is 'string' then " %s"
      else if typeof arg is 'number' || typeof arg is 'boolean' then " %o"
      else if typeof arg is 'object' && arg instanceof RegExp then " %o"
      else if typeof arg is 'object' && arg instanceof Date then " %s"
      else if typeof arg is 'object' && arg instanceof window.HTMLElement then " %o"
      else " %O"

    method = switch level
      when Levels.FATAL, Levels.ERROR then "error"
      when Levels.WARN then "warn"
      when Levels.INFO, Levels.GOOD, Levels.BAD then "info"
      when Levels.DEBUG then "debug"
      else "log"

    console[method](args...)

  _privateLogStream: -> @constructor._logStream

# Shortcuts
if @ledger.isDev
  @l = console.log.bind(console)
  @e = console.error.bind(console)
else
  @l = ->
  @e = ->
