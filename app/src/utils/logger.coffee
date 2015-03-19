@ledger.utils ?= {}

###
  Utility class for dealing with logs
###
class @ledger.utils.Logger

  constructor: (@_active) ->
    @_mode = if window.ledger.isDev then "debug" else "release"
    @store = new ledger.storage.ChromeStore("logs")

  setActive: (active) -> @_active = active

  isActive: -> @_active

  clear: ->
    @store.keys(
      (keys) ->
        now = new Date().getTime();
        window.ledger.utils.logger.store.remove key for key in keys when (now - key > 86400000) # 86400000 => 24h
    )

  _storeLog: (msg, msgType) ->
      now = new Date();
      log = {}
      log[now.getTime()] = {"date": now.toUTCString(), "type" : msgType, "msg" : msg}
      @clear()
      @store.set(log)

  debug: (msg) ->
    if @_active
      @_storeLog(msg, "DEBUG")
      if(@_mode == "debug")
        console.debug(msg)

  info: (msg) ->
    if @_active
       @_storeLog(msg, "INFO")
      if(@_mode == "debug")
        console.info(msg)

  warn: (msg) ->
    if @_active
      @_storeLog(msg, "WARN")
      if(@_mode == "debug")
        console.warn(msg)

  error: (msg) ->
    if @_active
      @_storeLog(msg, "ERROR")
      if(@_mode == "debug")
        console.error(msg)

@ledger.utils.logger = new ledger.utils.Logger(true)