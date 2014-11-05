
relationship = (item) ->


class @Model extends @EventEmitter

  _data: {}

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
        finalResults[k] = relationship v for k, v of results
        callback(finalResults)

  set: (key, value) ->
    @_data[key] = value

  save: (callback) ->
    @_data = {}


class @ModelTest extends Model