
ledger.db ?= {}
ledger.db.contexts ?= {}

class Collection

  constructor: (collection, context) ->
    @_collection = collection
    @_context = context

  insert: (model) ->
    model._object ?= {}
    model._object = @_collection.insert(model._object)
    @_context.notifyDatabaseChange()

  remove: (model) ->
    model._object = @_collection.remove(model._object)
    @_context.notifyDatabaseChange()

  update: (model) ->
    model._object = @_collection.update(model._object)
    @_context.notifyDatabaseChange()

  get: (id) -> @_modelize(@_collection.get(id))

  query: () ->
    query = @_collection.chain()
    data = query.data
    query.data = () =>
      @_modelize(data.call(@_collection))

  getCollection: () -> @_collection

  _modelize: (data) ->
    return null unless data?
    modelizeSingleItem = (item) ->
      Class = Model.AllModelClasses()[item.objType]
      new Class(@_context, item)
    if _.isArray(data)
      (modelizeSingleItem(item) for item in data)
    else
      modelizeSingleItem(data)

class ledger.db.contexts.Context

  constructor: (db) ->
    @_db = db
    @_collections = {}
    @_collections[collection.name] = new Collection(@_db.getCollection(collection.name), @) for collection in @_db.getDb().listCollections()
    @initialize()

  initialize: () ->
    modelClasses = Model.AllModelClasses()
    for className, modelClass of modelClasses
      collection = @getCollection(className)
      collection.getCollection().ensureIndex(index) for index in modelClass._indexes



  getCollection: (name) ->
    collection = @_collections[name]
    unless collection?
      collection = new Collection(@_db.getDb().addCollection(), @)
    collection

  notifyDatabaseChange: () ->
    @_db.scheduleFlush()


_.extend ledger.db.contexts,

  open: () ->
    ledger.db.contexts.main = new ledger.db.contexts.Context(ledger.db.main)

  close: () ->
