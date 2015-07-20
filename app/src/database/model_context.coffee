
ledger.database = {} unless ledger.database?
ledger.database.contexts = {} unless ledger.database.contexts?

collectionNameForRelationship = (object, relationship) ->
  switch relationship.type
    when 'many_one' then relationship.Class
    when 'many_many' then _.sortBy([relationship.Class, object.constructor.name], ((s) -> s)).join('_')
    when 'one_many' then relationship.Class
    when 'one_one' then relationship.Class

class Collection

  constructor: (collection, context) ->
    @_collection = collection
    @_context = context
    @_syncSubstores = {}

  insert: (model) ->
    model._object ?= {}
    model._object['objType'] = model.getCollectionName()
    model._object = @_collection.insert(model._object)
    @_insertSynchronizedProperties(model)
    @_context.notifyDatabaseChange()

  remove: (model) ->
    return unless model?._object
    id = model.getBestIdentifier()
    model.getBestIdentifier = -> id
    @_collection.remove(model._object['$loki'])
    @_removeSynchronizedProperties(model)
    @_context.emit "delete:" + _.str.underscored(model._object['objType']).toLowerCase(), model
    @_context.notifyDatabaseChange()

  update: (model) ->
    @_collection.update(model._object)
    @_updateSynchronizedProperties(model)
    @_context.notifyDatabaseChange()

  get: (id) -> @_modelize(@_collection.get(id))

  getRelationshipView: (object, relationship) ->
    viewName = "#{relationship.type}_#{relationship.name}_#{relationship.inverse}:#{object.getBestIdentifier()}"
    collectionName = collectionNameForRelationship(object, relationship)
    view = @_context.getCollection(collectionName).getCollection().getDynamicView(viewName)
    unless view?
      view = @_context.getCollection(collectionName).getCollection().addDynamicView(viewName, no)
      switch relationship.type
        when 'many_one'
          query = {}
          query["#{relationship.inverse}_id"] = object.getBestIdentifier()
          view.applyFind(query)
        when 'many_many' then throw 'Not implemented yet'
      if _(relationship.sort).isArray() and relationship.sort.length is 1
        view.applySimpleSort(relationship.sort[0][0], relationship.sort[0][1])
      else if _(relationship.sort).isArray()
        view.applySortCriteria(relationship.sort)
      else if _(relationship.sort).isFunction()
        view.applySort(relationship.sort)
    view.modelize = =>
      @_modelize(view.data())
    view.rematerialize()

  updateSynchronizedProperties: (data) ->
    synchronizedIndexField = @getModelClass()._synchronizedIndex.field
    objectDeclarations = _(data).pick (v, key) => key.match("^__sync_#{_.str.underscored(@_collection.name).toLowerCase()}_[a-zA-Z0-9]+_#{synchronizedIndexField}")
    existingsIds = []
    for key, index of objectDeclarations
      [__, objectId] = key.match("^__sync_#{_.str.underscored(@_collection.name).toLowerCase()}_([a-zA-Z0-9]+)_#{synchronizedIndexField}")
      existingsIds.push objectId
      objectNamePattern = "__sync_#{_.str.underscored(@_collection.name).toLowerCase()}_#{objectId}_"
      [object] = @getModelClass().find(_.object([synchronizedIndexField], [index]), @_context).data()
      synchronizedObject = {}
      existingsIds.push index
      for key, value of data when key.match(objectNamePattern)
        key = key.replace(objectNamePattern, '')
        synchronizedObject[key] = value
      @_context._syncStore.getAll(l)
      unless object?
        object = @getModelClass().create(synchronizedObject, @_context)
      else
        object.set k, v for k, v of synchronizedObject
      object.save()
    # Remove objects not present in sync store
    @getModelClass().where(((i) => !_.contains(existingsIds, i[@getModelClass().getBestIdentifierName()])), @_context).remove()
    return

  _getModelSyncSubstore: (model) -> @_syncSubstores["sync_#{_.str.underscored(model.getCollectionName()).toLowerCase()}_#{model.getBestIdentifier()}"] ||= @_context._syncStore.substore("sync_#{_.str.underscored(model.getCollectionName()).toLowerCase()}_#{model.getBestIdentifier()}")

  _insertSynchronizedProperties: (model) -> @_updateSynchronizedProperties(model)

  _updateSynchronizedProperties: (model) ->
    return unless model.hasSynchronizedProperties()
    dataToSet = {}
    dataToRemove = {}
    for key, value of model.getSynchronizedProperties()
      (if value? then dataToSet else dataToRemove)[key] = value
    @_getModelSyncSubstore(model).set(dataToSet)
    @_getModelSyncSubstore(model).remove(_(dataToRemove).keys())

  _removeSynchronizedProperties: (model) ->
    l "Attempt removal", model
    return unless model.hasSynchronizedProperties()
    l "Remove from",  @_getModelSyncSubstore(model), model.constructor.getSynchronizedPropertiesNames()
    @_getModelSyncSubstore(model).remove(model.constructor.getSynchronizedPropertiesNames())

  query: () ->
    @_wrapQuery(@_collection.chain())

  _wrapQuery: (query) ->
    return query if query._wrapped
    {data, sort, limit, simplesort} = query
    query.data = () =>
      @_modelize(data.call(query))
    query.first = () => @_modelize(data.call(query)[0])
    query.last = () =>
      d = data.call(query)
      @_modelize(d[d.length - 1])
    query.all = query.data
    query.count = () -> data.call(query).length
    query.remove = -> object.delete() for object in query.all()
    query.sort = () => @_wrapQuery(sort.apply(query, arguments))
    query.limit = () => @_wrapQuery(limit.apply(query, arguments))
    query.simpleSort = () => @_wrapQuery(simplesort.apply(query, arguments))
    query._wrapped = true
    query

  getCollection: () -> @_collection
  getModelClass: -> ledger.database.Model.AllModelClasses()[@getCollection().name]

  _modelize: (data) ->
    return null unless data?
    modelizeSingleItem = (item) =>
      Class = ledger.database.Model.AllModelClasses()[item.objType]
      new Class(@_context, item)
    if _.isArray(data)
      (modelizeSingleItem(item) for item in data when item?)
    else
      modelizeSingleItem(data)

  refresh: (model) ->
    model._object = @_collection.get model.getId()
    model

class ledger.database.contexts.Context extends EventEmitter

  constructor: (db, syncStore = ledger.storage.sync) ->
    @_db = db
    @_collections = {}
    @_synchronizedCollections = {}
    @_syncStore = syncStore
    for collection in @_db.getDb().listCollections()
      @_collections[collection.name] = new Collection(@_db.getDb().getCollection(collection.name), @)
      @_listenCollectionEvent(@_collections[collection.name])
    @_syncStore.on 'pulled', (@onSyncStorePulled = @onSyncStorePulled.bind(this))
    @initialize()

  initialize: () ->
    modelClasses = ledger.database.Model.AllModelClasses()
    for className, modelClass of modelClasses
      @_synchronizedCollections[className] = modelClass if modelClass._synchronizedIndex?
      collection = @getCollection(className)
      collection.getCollection().DynamicViews = []
      collection.getCollection().ensureIndex(index.field) for index in modelClass._indexes if modelClass.__indexes?
    try
      new ledger.database.MigrationHandler(@).applyMigrations()
    catch er
      e er

  getCollection: (name) ->
    collection = @_collections[name]
    unless collection?
      collection = new Collection(@_db.getDb().addCollection(name), @)
      @_collections[name] = collection
      @_listenCollectionEvent(collection)
    collection

  notifyDatabaseChange: () ->
    @_db.scheduleFlush()

  close: ->
    @_syncStore.off 'pulled', @onSyncStorePulled

  _listenCollectionEvent: (collection) ->
    collection.getCollection().on 'insert', (data) =>
      @emit "insert:" + _.str.underscored(data['objType']).toLowerCase(), @_modelize(data)
    collection.getCollection().on 'update', (data) =>
      @emit "update:" + _.str.underscored(data['objType']).toLowerCase(), @_modelize(data)

  onSyncStorePulled: ->
    @_syncStore.getAll (data) =>
      for name, collection of @_collections
        continue unless collection.getModelClass().hasSynchronizedProperties()
        collectionData = _(data).pick (v, k) -> k.match("__sync_#{_.str.underscored(name).toLowerCase()}")?
        unless _(collectionData).isEmpty()
          collection.updateSynchronizedProperties(collectionData)
        else
          # delete all
          collection.getModelClass().chain(this).remove()
      @emit 'synchronized'

  refresh: ->
    d = ledger.defer()
    ledger.storage.sync.pull().then (uptodate) =>
      return d.resolve(no) if uptodate is yes
      @once 'synchronized', ->
        d.resolve(yes)
    .fail () ->
      d.resolve(no)
    .done()
    d.promise

  _modelize: (data) -> @getCollection(data['objType'])?._modelize(data)

_.extend ledger.database.contexts,

  open: () ->
    ledger.database.contexts.main = new ledger.database.contexts.Context(ledger.database.main)

  close: () ->
    ledger.database.contexts.main?.close()
