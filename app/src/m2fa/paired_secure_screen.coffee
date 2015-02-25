
ledger.m2fa ?= {}

VERSION = 1

class ledger.m2fa.PairedSecureScreen
  id: null # Pairing id
  createdAt: null # Pairing creation date
  name: null # Pairing name
  version: VERSION

  constructor: (base) ->
    @_deserialize(base) if base?

  _deserialize: (base) ->
    # Handle versions here
    @id = base['id']
    @createdAt = new Date(base['created_at'])
    @name = base['name']
    @version = VERSION

  toStore: (store) ->
    serialized =
      id: @id
      created_at: @createdAt.getTime()
      name: @name
      version: VERSION
    data = {}
    data["__m2fa_#{@id}"] = serialized
    store.set data
    @

  toSyncedStore: () -> @toStore(ledger.storage.sync)

  @fromStore: (id, store, callback = _.noop) ->
    closure = new CompletionClosure()
    closure.onComplete callback
    store.get "__m2fa_#{id}", (objects) ->
      result = if objects.length > 0 then new @(objects[0]) else null
      error = if objects.length is 0 then ledger.errors.NotFound else null
      closure.complete(result, error)
    closure.readonly()

  @fromSyncedStore: (id, callback = _.noop) -> @fromStore(id, ledger.storage.sync, callback)

  @create: (id, name) -> new @(id: id, name: name, created_at: new Date().getTime(), version: VERSION)

  @getAllFromStore: (store, callback = _.noop) ->
    closure = new CompletionClosure()
    closure.onComplete callback
    store.keys (keys) =>
      keys = _.filter(keys, (key) -> key.match(/^__m2fa_/))
      return closure.success([]) if keys.length is 0
      store.get keys, (objects) =>
        screens = (new @(object) for k, object of objects)
        closure.success(screens)
    closure.readonly()

  @getAllFromSyncedStore: (callback = _.noop) -> @getAllFromStore(ledger.storage.sync, callback)

  @getMostRecentFromStore: (store, callback = _.noop) ->
    closure = new CompletionClosure(callback)
    @getAllFromStore store, (screens) ->
      return closure.fail(ledger.errors.NotFound) if screens.length is 0
      closure.success(_(screens).max (screen) -> screen.createdAt.getTime())
    closure.readonly()

  @getMostRecentFromSyncedStore: (callback = _.noop) -> @getMostRecentFromStore(ledger.storage.sync, callback)

