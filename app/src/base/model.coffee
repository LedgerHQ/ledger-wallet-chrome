
# Creates a relationship object from a store object or array reference. This fucntion is private to this file
# @return [Model|Collection]
# @private
relationship = (item) ->
  l item

class @Model extends @EventEmitter

  constructor: (base) ->
    @_data = base
    @_id = @_data?._id
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
      for k, v of results
        if _(v).isStoreReference()
          relationships.push v.__uid
        else
          finalResults[k] = v
      return callback(finalResults) if relationships.length == 0
      ledger.storage.local.get relationships, (results) =>
        finalResults[k] = relationship(v) for k, v of results
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

  set: (key, value) ->
    @_data ?= {}
    @_data[key] = value

  isInserted: () -> @__uid?

  isUpdated: () -> @_data?

  isSaving: () -> @_saving?

  save: (callback = _.noop) ->
    @_saving = yes

    onDone = () ->
      @_saving = null
      callback arguments

    return @_performFind(onDone) if @_find?
    @_performSave(onDone)

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

  getCollectionName: () -> _(@).getClass().getCollectionName()

  getCollection: () -> ledger.collections[@getCollectionName()]

  @getCollection: () -> ledger.collections[@getCollectionName()]

  @init: (modelClass) ->
    unless modelClass.getCollection()
      ledger.collections.createCollection(modelClass.getCollectionName())

  # Safely performs a callback on the current model
  _perform: (cb = _.noop) ->

_.mixin
  model: (object) ->
    return null unless object.__type?
    model = new window[object.__type]()
    model.__uid = object.__uid
    model