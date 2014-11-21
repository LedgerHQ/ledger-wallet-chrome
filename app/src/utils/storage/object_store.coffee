# This store is able to store objects in a 'slave store' (i.e. you can use an object store with a secure store or synced
# store). Each inserted object must have a unique object identifier ('__uid' property). If they do not, the store assigns
# them a unique id. Objects can be retrieved later by using their unique identifier.
class @ledger.storage.ObjectStore extends ledger.storage.Store

  # ObjectStore constructor
  # @param [ledger.storage.Store] store The slave store used to save data within
  constructor: (@store) ->
    @store.get '__lastUniqueIdentifier', (result) =>
      @_lastUniqueIdentifier = if result?.__lastUniqueIdentifier? and not isNaN(result?.__lastUniqueIdentifier) then result.__lastUniqueIdentifier else 1
      @emit 'initialized'

  # Perform an operation on the store safely
  # @private
  perform: (cb) ->
    if @_lastUniqueIdentifier?
      do cb
    else
      @once 'initialized', =>
        setTimeout(cb, 0)

  # Saves one or many objects in the store. Once data are inserted, it calls back the closure with the given objects assigned
  # with their ids.
  # @param [Array|Object] objects One or many object(s) to save in the store
  # @param [Function] callback A function to fire up when data are inserted.
  set: (objects, callback) ->
    return @set([objects], callback) unless _.isArray(objects)
    @perform =>
      insertionBatch = {}
      for object in objects
        if _.isArray(object)
          @_flattenArray(object, insertionBatch)
        else if _.isObject(object)
          @_flattenStructure(object, insertionBatch)
      onInserted = (->
        callback?(insertionBatch)
      ).bind(this)
      idsToUpdate = (uid for uid, value of insertionBatch)
      @store.get idsToUpdate, (items) =>
        for uid, value of items
          insertionBatch[uid] = _.extend(JSON.parse(value), insertionBatch[uid])
        @store.set insertionBatch, ->
          setTimeout callback, 0

  # Gets items from the store using their unique object identifiers and returns them by calling back a closure.
  # @param [Array|Value] ids Id(s) of the item(s) to fetch
  # @param [Function] callback Called with an object containing all requested objects
  get: (ids, callback) ->
    return @get([ids], callback) unless _.isArray(ids)
    onGetItems = ( (result) ->
      objects = {}
      for uid, value of result
        object = JSON.parse value
        if object.__type is 'array'
          object = object.content
          object.__uid = uid
        objects[uid] = object
      callback(objects)
    ).bind(this)

    @store.get ids, (result) ->
      setTimeout(( -> onGetItems result ), 0)

  exists: (ids, callback) ->
    return @exists([ids], callback) unless _.isArray(ids)
    onGetItems = ( (result) ->
      objects = {}
      for id in ids
        objects[id] = if result[id]? then yes else no
      callback(objects)
    ).bind(this)

    @store.get ids, (result) ->
      setTimeout(( -> onGetItems result ), 0)

  # Removes items from the store using their unique object identifiers.
  # @param [Array|Value] ids Id(s) of the item(s) to fetch
  # @param [Function] callback Called once items are removed from the store.
  remove: (ids, callback) ->
    return @remove([ids], callback) unless _.isArray(ids)

    @store.get ids, (result) ->
      setTimeout(( -> callback?() ), 0)

  clear: (callback) ->
    @store.clear(callback)

  # Creates a unique identifier for a new object
  # @private
  createUniqueObjectIdentifier: (prefix = 'auto', id) ->
    @store.set({__lastUniqueIdentifier: @_lastUniqueIdentifier + 1}) if id?
    id = if id? then id else - (@_lastUniqueIdentifier++)
    [id, ledger.crypto.SHA256.hashString(prefix + id)]

  # Breaks a complex object (with properties, sub-objects, arrays) into a list of simple objects and replaces sub-objects
  # into reference. (.i.e. {name: 'ledger', and: {name: 'wallet'}} becomes {id01: {name: 'ledger', and: ref id02} id02: {name: 'wallet'}})
  # @private
  _flattenStructure: (structure, destination) ->
    object = {}
    for key, value of structure
      _value = _(value)
      continue if _value.isFunction() or _value.isStoreReference()
      if _value.isArray()
        arrayId = @_flattenArray(value, destination).__uid
        object[key] = {__type: 'ref', __uid:arrayId}
      else if _value.isObject()
        valueId = @_flattenStructure(value, destination).__uid
        object[key] = {__type: 'ref', __uid:valueId}
      else
        object[key] = value
    unless object.__uid?
      [id, uid] = @createUniqueObjectIdentifier()
      object.__uid = uid
    destination[object.__uid] = object
    object

  # Used by _flattenStructure to break array in reference
  # @private
  _flattenArray: (structure, destination) ->
    array = []
    for value in structure
      _value = _(value)
      continue if _value.isFunction()
      if _value.isStoreReference()
        array.push value
      else if _value.isArray()
        arrayId = @_flattenArray(value, destination).__uid
        array.push {__type: 'ref', __uid:arrayId}
      else if _value.isObject()
        valueId = @_flattenStructure(value, destination).__uid
        array.push {__type: 'ref', __uid:valueId}
      else
        array.push value
    array.__uid = structure.__uid
    array.__modCount = if structure.__modCount? then structure.__modCount else 0
    unless array.__uid?
      [id, uid] = @createUniqueObjectIdentifier()
      array.__uid = uid
    destination[array.__uid] = {__type: 'array', __uid: array.__uid, content: array}
    array

_.mixin
  # Tests if the given object is an ObjectStore reference or not
  isStoreReference: (object) -> if object? and object.__type == 'ref' then yes else no

