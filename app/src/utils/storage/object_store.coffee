class @ledger.storage.ObjectStore extends EventEmitter

  constructor: (@store) ->
    @store.getItem '__lastUniqueIdentifier', (result) =>
      @_lastUniqueIdentifier = if result?.__lastUniqueIdentifier? then result.__lastUniqueIdentifier else 0
      @emit 'initialized'

  perform: (cb) ->
    if @__lastUniqueIdentifier?
      do cb
    else
      @once 'initialized', =>
        setTimeout(cb, 0)

  setItems: (objects, callback) ->
    return @setItems([objects], callback) unless _.isArray(objects)
    @perform =>
      insertionBatch = {}
      for object in objects
        @_flattenStructure(object, insertionBatch)
      l JSON.stringify(insertionBatch, undefined, 2)
      @store.setItem insertionBatch, ->
        setTimeout callback, 0

  getItems: (ids, callback) ->
    return @getItems([ids], callback) unless _.isArray(ids)

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

    @store.getItem ids, (result) ->
      setTimeout(( -> onGetItems result ), 0)

  createUniqueObjectIdentifier: ->
    id = @_lastUniqueIdentifier++
    @store.setItem({__lastUniqueIdentifier: @_lastUniqueIdentifier})
    ledger.crypto.SHA256.hashString('auto_' + id)

  _flattenStructure: (structure, destination) ->
    object = {}
    for key, value of structure
      _value = _(value)
      continue if _value.isFunction()
      if _value.isArray()
        arrayId = @_flattenArray(value, destination).__uid
        object[key] = {__type: 'ref', __uid:arrayId}
      else if _value.isObject()
        valueId = @_flattenStructure(value, destination).__uid
        object[key] = {__type: 'ref', __uid:valueId}
      else
        object[key] = value
    unless object.__uid?
      object.__uid = @createUniqueObjectIdentifier()
    destination[object.__uid] = object
    object

  _flattenArray: (structure, destination) ->
    array = []
    for value in structure
      _value = _(value)
      continue if _value.isFunction()
      if _value.isArray()
        arrayId = @_flattenArray(value, destination).__uid
        array.push arrayId
      else if _value.isObject()
        valueId = @_flattenStructure(value, destination).__uid
        array.push valueId
      else
        array.push value
    unless array.__uid?
      array.__uid = @createUniqueObjectIdentifier()
    destination[array.__uid] = {__type: 'array', __uid: array.__uid, content: array}
    array

_.mixin
  isStoreReference: (object) -> object?.__type? == 'ref'

