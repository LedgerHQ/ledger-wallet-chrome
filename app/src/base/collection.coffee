
@ledger.collections ?= {}
@ledger.collections.createCollection = (collectionName) ->
  className = _.str.classify(collectionName)
  ledger.collections[className] = class Collection extends ledger.collections.Collection
  ledger.collections[className].name =
  ledger.collections[collectionName] = ledger.collections[className].global()

class Iterator

  constructor: (@collection = [], @current = 0, @direction = 1) ->
    if @current == -1
      @current = @collection.length
    @current = if @direction > 0 then @current - 1 else @current + 1

  length: () -> @collection.length
  hasNext: () -> @current < @length()
  hasPrevious: () -> @current <= 0

  next: (callback) ->
    @direction = 1
    @current += 1
    return callback(null, @) unless @hasNext()
    ref = @collection[@current]
    ledger.storage.local.get ref.__uid, (result) =>
      callback(result[ref.__uid])

  previous: (callback) ->
    @current -= 1
    @direction = -1
    return callback(null, @) unless @hasPrevious()

    ref = @collection[@current]
    ledger.storage.local.get ref.__uid, (result) =>
      callback(result[ref.__uid])

  refresh: (callback) ->
    ledger.storage.local.get @collection.__uid, (result) =>
      callback(new Iterator(result[@collection.__uid] , @current, @direction))

class ledger.collections.Collection extends EventEmitter

  insert: (object, callback = _.noop) ->
    @_perform =>
      ledger.storage.local.get @getUid(), (result) =>

        object._data = {} unless object._data
        object._data.__uid = object.getUid() unless object._data.__uid?

        collection = result[@getUid()]

        # First time creation of the collection
        unless collection?
          collection = [object._data]
          collection.__uid = @getUid()
          ledger.storage.local.set [collection], =>
            callback(yes)
        else
          if _(collection).where(__uid: object._data.__uid).length > 0
            callback(no) # Object already inserted
          else
            collection.push object._data
            ledger.storage.local.set [collection], =>
              callback(yes)

  remove: (object, callback) ->

  length: (callback) -> @iterator (it) -> callback it.length()

  each: (callback) ->
    @iterator (it) =>
      onNext = (result) ->
        callback(result)
        it.next(onNext) if it.hasNext()
      it.next onNext

  toArray: (callback) ->
    ledger.storage.local.get @getUid(), (result) =>
      collection = result[@getUid()]
      return callback([]) unless collection?
      ids = []
      for item in collection
        ids.push item.__uid
      ledger.storage.local.get ids, (result) =>
        array = []
        for id in ids
          array.push result[id]
        callback(array)

  iterator: (callback) ->
    ledger.storage.local.get @getUid(), (result) => callback(new Iterator(result[@getUid()], 0))

  reverseIterator: (callback) ->
    ledger.storage.local.get @getUid(), (result) => callback(new Iterator(result[@getUid()], -1, -1))

  @global: () ->
    globalCollection = new @
    self = @
    globalCollection.getUid = () ->
      globalCollection.__uid ?= ledger.storage.local.createUniqueObjectIdentifier("global_#{_.str.underscored(self.name)}", 42)[1]
      globalCollection.__uid
    globalCollection.isGlobal = () -> yes
    globalCollection

  @relation: (arrayUid) ->
    collection = new @
    collection.__uid = arrayUid
    globalCollection.isGlobal = () -> no
    collection

  _perform: (cb) ->
    if not @_initialized?
      ledger.storage.local.on 'close', ->
        globalCollection.__uid = null
      @_initialized = yes
    do cb
