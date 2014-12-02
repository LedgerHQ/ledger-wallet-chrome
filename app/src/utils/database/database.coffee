
ledger.db ?= {}

class Database extends EventEmitter

  constructor: (name) ->
    @_name = name

  load: (callback) ->
    ledger.storage.databases.get @_name, (json) =>
      @_db = new loki()
      @_db.loadJSON json
      @_db.save = @scheduleFlush.bind(this)
      callback?()
      @emit 'loaded'

  perform: (callback) ->
    if @_db?
      callback?()
    else
      @once 'loaded', callback

  flush: () ->
    clearTimeout @_scheduledFlush if @_scheduledFlush?

  scheduleFlush: () ->
    clearTimeout @_scheduledFlush if @_scheduledFlush?
    @_scheduledFlush = setTimeout =>
      @_scheduledFlush = null
      @flush()
    , 1000

  isLoaded: () -> if @_db? then yes else no

  getDb:() ->
    throw 'Unable to use database right now (not loaded)' unless @_db?
    @_db

  close: () ->
    @flush()
    @_db = null

_.extend ledger.db,

  init: (callback) ->
    ledger.db.main = ledger.db.open 'main', ->
      callback?()

  open: (databaseName, callback) ->
    db = new Database databaseName
    db.load callback
    db

  close: () ->


