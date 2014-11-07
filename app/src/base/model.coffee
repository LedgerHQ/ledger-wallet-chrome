class @Model extends @EventEmitter

  constructor: (base) ->
    @_data = base
    @_id = @_data?._id
    @__uid = @_data?.__uid
    @_initializeRelationships()
    @initilialize?()

  getUid: () -> @__uid

  getId: () -> @_id

  get: (callback) ->
    return @_performFindOrCreate(callback) if @_findOrCreate?
    @_performGet(callback)

  _performGet: (callback) ->
    throw 'Object without id cannot perform get operation' unless @getUid()
    ledger.storage.local.get @getUid(), (results) =>
      results = results[@getUid()]
      return callback(null) unless results?
      finalResults = {}
      relationships = []
      relationshipNames = {}
      for k, v of results
        if _(v).isStoreReference()
          relationships.push v.__uid
          relationshipNames[ v.__uid] = k
        else
          finalResults[k] = v
      return callback(finalResults) if relationships.length == 0
      ledger.storage.local.get relationships, (results) =>
        finalResults[relationshipNames[k]] = @relationship(relationshipNames[k], v) for k, v of results
        callback(finalResults)

  exists: (callback) ->
    id = switch
      when @getUid()? then @getUid()
      when @_findOrCreate? then @_findOrCreate.__uid
      when @_find?  then @_find.__uid
    ledger.storage.local.exists @_findOrCreate.__uid, (result) =>
      if result[id]?
        @__uid = id
        @_find = null
        @_findOrCreate = null
        callback(yes)
      else
        callback(no)
    @

  set: (key, value) ->
    @_data ?= {}
    if _(value).isKindOf Model
      if value.isInserted()
        @_data[key] = _(value).modelReference()
      else
        value._data ?= {}
        value._data.__uid ?= value.__uid
        value._data._id ?= value._id
        value._data.__type = _(value).getClassName()
        value._data.__uid ?= ledger.storage.local.createUniqueObjectIdentifier(value._data.__type, value._data._id)[1]
        @_data[key] = value._data
    else
      @_data[key] = value
    @

  isInserted: () -> if @__uid? then yes else no

  isUpdated: () -> if @_data? then yes else no

  isSaving: () -> if @_saving? then yes else no

  save: (callback = _.noop) ->
    @_saving = yes

    onDone = () ->
      @_saving = null
      callback arguments

    return @_performFind(onDone) if @_find?
    @_performSave(onDone)
    @

  remove: (callback = _.noop) ->
    throw 'Cannot remove a model never inserted' unless @isInserted()
    @getCollection().removeItemByUid @getUid(), () =>
      ledger.storage.local.remove [@getUid()], callback
    @

  _performSave: (callback) ->
    inserted = @isInserted()
    data = @_data
    @_data = null
    data.__type = _(this).getClassName()
    data.__uid = switch
      when inserted then @getUid()
      when not inserted and data.__uid? then data.__uid
      else ledger.storage.local.createUniqueObjectIdentifier(data.__type, data._id)[1]
    data = _(data).omit(['_id']) if inserted and data._id?
    if not inserted
      @_data = data
      @getCollection().insert this, () =>
        @_data = null
        @__uid = data.__uid
        callback(yes)
    else
      ledger.storage.local.set data, () => callback(yes)

  _performFind: (callback) ->
    @exists (exists) ->
      if exists
        @_performSave(callback)
      else
        callback(no)

  _performFindOrCreate: (callback) ->
    ledger.storage.local.exists @_findOrCreate.__uid, (result) =>
      _findOrCreate = @_findOrCreate
      @_findOrCreate = undefined
      if result[_findOrCreate.__uid]
        @__uid = _findOrCreate.__uid
        return @_performGet(callback)
      @_data = _findOrCreate.base
      @_data._id = _findOrCreate._id
      @_data.__uid = _findOrCreate.__uid
      @save () =>
        @_performGet callback

  _initializeRelationships: () ->


  @create: (base = {}) -> new @(base)

  @findOrCreate: (id, base = {}) ->
    object = new @()
    object._id = id
    object._findOrCreate = {_id: id, __uid: ledger.storage.local.createUniqueObjectIdentifier(@name, id)[1], base: base}
    object

  @find: (id) ->
    object = new @()
    object._id = id
    object._find = {_id: id, __uid: ledger.storage.local.createUniqueObjectIdentifier(@name, id)[1]}
    object

  @getCollectionName: () -> _.pluralize(_.str.underscored(@name))

  # Creates a relationship object from a store object or array reference. This fucntion is private to this file
  # @return [Model|Collection]
  # @private
  relationship: (relationName, item) ->
    unless _(item).isArray()
      obj = new window[item.__type]()
      obj.__uid = item.__uid
      return obj
    else
      collectionName = _(@).getClass()._relations.many[relationName]
      throw "Unknown hasMany relation '#{relationName}'" unless collectionName?
      collection = new ledger.collections[collectionName.className]()
      collection.__uid = item.__uid
      return collection

  getCollectionName: () -> _(@).getClass().getCollectionName()

  getCollection: () -> ledger.collections[@getCollectionName()]

  @getCollection: () -> ledger.collections[@getCollectionName()]

  @init: ->
    unless @getCollection()
      ledger.collections.createCollection(@getCollectionName())

  ## Relations

  @hasOne: (relations) ->
    @._relations ?= {}
    @._relations.one ?= {}
    for relationName, relationClass of relations
      @_relations.one[relationName] = {className: relationClass}
      @::["get#{_.str.classify(relationName)}"] = (callback) ->
        ledger.storage.local.get @getUid(), (result) =>
          if result[@getUid()]?[relationName]?
            obj = new window[relationClass]()
            obj.__uid = result[@getUid()][relationName].__uid
            callback(obj)
          else
            callback()

  @hasMany: (relations) ->
    @._relations ?= {}
    @._relations.many ?= {}
    for relationName, relationClass of relations
      @_relations.many[relationName] = {className: relationClass}
      @::["get#{_.str.classify(relationName)}"] = (callback) ->
        ledger.storage.local.get @getUid(), (result) =>
          if result[@getUid()]?[relationName]?
            obj = new ledger.collections[relationClass]()
            obj.__uid = result[@getUid()][relationName].__uid
            callback(obj)
          else
            callback(null)

_.mixin
  model: (object) ->
    return null unless object.__type?
    model = new window[object.__type]()
    model.__uid = object.__uid
    model

  modelReference: (object) ->
    return null unless object?.__uid?
    {__type: 'ref', __uid: object.__uid}