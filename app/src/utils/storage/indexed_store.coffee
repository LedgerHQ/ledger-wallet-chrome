
NodeType =
  ARRAY: 0
  OBJECT: 1
  VALUE: 2
  UNDEFINED: 3

# A special type of store with an index table. This store is able to deal with special types (objects, arrays) and
# allow to create real data structure (basic stores are only able to deal with key/value entry).
# This store takes another store and manages it
class @ledger.storage.IndexedStore extends EventEmitter

  # @param [ledger.storage.Store] store The store that will be managed by the indexed store
  constructor: (@store) ->
    @store.getItem '__index__', (results) =>
      if results.__index__?
        @_index = JSON.parse results.__index__
      else
        @_index = {items: {}}
      @emit 'initialized'

  # Perform an operation once the store is correctly loaded
  # @private
  perform: (callback) ->
    if @_index?
      do callback
    else
      @once 'initialized', () ->
        setTimeout callback, 0

  setObjectItem: (key, object, callback, inserts = {}) ->
    @perform =>
      @_index.items[key] = @_createItem(key) unless @_index.items[key]?
      _.str.parseObjectPath(key)
      for k, value of object
        continue unless value?
        indexKey = "#{key}.#{k}"
        if _.isArray(value)
          @setArrayItem(indexKey, value, null, inserts)
          @_index.items[key].object[k] = NodeType.ARRAY
        else if _.isObject(value)
          @setObjectItem(indexKey, value, null, inserts)
          @_index.items[key].object[k] = NodeType.OBJECT
        else if not _.isFunction(value)
          @_index.items[key].object[k] = NodeType.VALUE
          @setValueItem(indexKey, value, null, inserts)
      l @_index
      @store.setItem(inserts, callback) unless callback is null
      inserts

  setArrayItem: (key, array, callback, inserts = {}) ->
    @perform =>
      @_index.items[key] = @_createItem(key) unless  @_index.items[key]?

      @store.setItem(inserts, callback) unless callback is null
      insert


  setValueItem: (key, value, callback, inserts = {}) ->
    @perform =>
      @_index.items[key] = @_createItem(key) unless  @_index.items[key]?
      @_index.items[key].value = value?
      inserts[key] = value
      @store.setItem(inserts, callback) unless callback is null
      inserts


  pushItemInArray: (arrayKey, item, callback) ->

  removeItemFromArray: (arrayKey, item, callback) ->

  _ensurePathExists: (pathString) ->
    path = _.str.parseObjectPath pathString

  _createItem: (key) -> {object: {}, array: {}}


