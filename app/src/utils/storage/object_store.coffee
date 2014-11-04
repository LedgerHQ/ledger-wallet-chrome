class @ledger.storage.ObjectStore extends EventEmitter

  constructor: (@store) ->
    @store.getItem '__lastUniqueIdentifier', =>
      @_lastUniqueIdentifier = 0
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
      l insertionBatch
      @store.setItem insertionBatch, ->
        setTimeout callback, 0
        chrome.storage.local.get null, (items) ->
          l items
          chrome.storage.local.clear()

  getItems: (keys, callback) ->

  createObjectUniqueIdentifier: -> @_lastUniqueIdentifier++

  _flattenStructure: (structure, destination) ->
    object = {}
    for key, value of structure
      _value = _(value)
      continue if _value.isFunction()
      if _value.isObject()
        valueId = @_flattenStructure(value, destination).__uid
        object[key] = valueId
      else if _value.isArray()
        arrayId = @_flattenArray(value, destination).__uid
        object[key] = valueId
      else
        object[key] = value
    unless object.__uid?
      object.__uid = @createObjectUniqueIdentifier()
    destination[object.__uid] = object
    object

  _flattenArray: (array, destination) ->



