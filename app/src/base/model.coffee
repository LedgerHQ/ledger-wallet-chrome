
# Creates a relationship object from a store object or array reference. This fucntion is private to this file
# @return [Model|Collection]
# @private
relationship = (item) ->
  l item

class @Model extends @EventEmitter

  constructor: (base) ->
    @_data = base

  getId: () -> @__uid

  get: (keys, callback) ->
    _keys = _(keys)
    ledger.storage.local.get @getId(), (results) =>
      finalResults = {}
      relationships = []
      for k, v of results
        if _(v).isStoreReference() and _keys.contains(k)
          relationships.push v.__uid
        else
          finalResults[k] = v
      return callback(finalResults) if relationships.length == 0
      ledger.storage.local.get relationships, (results) =>
        finalResults[k] = relationship(v) for k, v of results
        callback(finalResults)

  set: (key, value) ->
    @_data[key] = value

  isInserted: () -> @__uid?

  isUpdated: () -> @_data?

  isSaving: () -> @_saving?

  save: (callback = _.noop) ->
    @_saving = yes
    inserted = @isInserted()
    data = @_data
    @_data = null
    unless inserted
      data.__type = _(this).getClassName()
      data.__uid = ledger.storage.local.createUniqueObjectIdentifier(data.__type, data.id)
    ledger.storage.local.set data, () =>
      @_saving = null
      unless inserted
        @getCollection().insert @
      else
        callback()

  @create: (base = {}) -> new @(base)

  @getCollectionName: () -> _.pluralize(_.str.underscored(_(@).getClassName()))

  getCollectionName: () -> _(@).getClass().getCollectionName()

  getCollection: () -> ledger.collections[@getCollectionName()]

  @init: (modelClass) ->
    unless modelClass.getCollection()
      ledger.collections.createCollection(modelClass.getCollectionName())

  # Safely performs a callback on the current model
  _perform: (cb = _.noop) ->
