
ledger.database ?= {}

class ledger.database.Database extends EventEmitter

  constructor: (name, persistenceAdapter) ->
    @_name = name
    @_persistenceAdapter = persistenceAdapter

  load: (callback) ->
    @_persistenceAdapter.serialize().then (json) =>
      try
        @_migrateJsonToLoki125 json
        @_db = new loki(@_name, ENV: 'BROWSER')
        @_db.loadJSON JSON.stringify(json[@_name]) if json[@_name]?
        @_db.save = @scheduleFlush.bind(this)
        for collection in @listCollections()
          collection.setChangesApi on
      catch er
        e er
        callback?()
        @emit 'loaded'

  addCollection: (collectionName) ->
    collection = @_db.addCollection(collectionName)
    collection.setChangesApi on
    collection

  listCollections: () -> @_db.listCollections()

  getCollection: (collectionName) -> @_db.getCollection(collectionName)

  _migrateJsonToLoki125: (json) ->
    if !json['__version']? or json['__version'] isnt '1.2.5'
      @_migrateDbJsonToLoki125(value) for key, value of json when !key.match(/^(__version)$/)

  _migrateDbJsonToLoki125: (dbJson) ->
    return unless dbJson? and dbJson['collections']?
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
      changes = @_db.generateChangesNotification()
      @_persistenceAdapter.saveChanges(changes).then -> callback?()
      @_db.clearChanges()

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

  delete: (callback) ->
    @_persistenceAdapter.delete().then () -> callback?()

  close: () ->
    @flush()
    @_db = null

_.extend ledger.database,

  init: (callback) ->
    ledger.database.main = ledger.database.open 'main', ->
      callback?()

  open: (databaseName, callback) ->
    db = new ledger.database.Database(databaseName, ledger.storage.databases)
    db.load callback
    db

  close: () ->
    ledger.database.main?.close()
    ledger.database.main = null


