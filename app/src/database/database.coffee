
ledger.database ?= {}

class Database extends EventEmitter

  constructor: (name, store) ->
    @_name = name
    @_store = store

  load: (callback) ->
    @_store.get @_name, (json) =>
      try
        @_migrateJsonToLoki125 json
        @_db = new loki(@_name, ENV: 'BROWSER')
        @_db.loadJSON JSON.stringify(json[@_name]) if json[@_name]?
        @_db.save = @scheduleFlush.bind(this)
      catch er
        e er
      callback?()
      @emit 'loaded'

  _migrateJsonToLoki125: (json) ->
    if !json['__version']? or json['__version'] isnt '1.2.5'
      @_migrateDbJsonToLoki125(value) for key, value of json when !key.match(/^(__version)$/)

  _migrateDbJsonToLoki125: (dbJson) ->
    for collection in dbJson['collections']
      for item in collection['data']
        item['$loki'] = item['id'] if item['id']
        item['id'] = item['originalId'] or item['$loki']
        delete item['originalId']

  perform: (callback) ->
    if @_db?
      callback?()
    else
      @once 'loaded', callback

  flush: (callback) ->
    @perform =>
      clearTimeout @_scheduledFlush if @_scheduledFlush?
      serializedData = {}
      serializedData[@_name] = @_db
      @_store.set serializedData, callback

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

_.extend ledger.database,

  init: (callback) ->
    ledger.database.main = ledger.database.open 'main', ->
      callback?()

  open: (databaseName, callback) ->
    db = new Database(databaseName, ledger.storage.databases)
    db.load callback
    db

  close: () ->
    ledger.database.main?.close()
    ledger.database.main = null


