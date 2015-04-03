
ledger.m2fa ?= {}

VERSION = 1

class ledger.m2fa.PairedSecureScreen
  id: null # Pairing id
  createdAt: null # Pairing creation date
  name: null # Pairing name
  uuid: null # Phone UUID
  platform: null # Phone platform
  version: VERSION

  constructor: (base) ->
    @_deserialize(base) if base?

  _deserialize: (base) ->
    # Handle versions here
    @id = base['id']
    @createdAt = new Date(base['created_at'])
    @name = base['name']
    @uuid = base['uuid']
    @platform = base['platform']
    @version = VERSION

  toStore: (store) ->
    serialized =
      id: @id
      created_at: @createdAt.getTime()
      name: @name
      uuid: @uuid
      platform: @platform
      version: VERSION
    data = {}
    data["__m2fa_#{@id}"] = serialized
    store.set data
    @

  toSyncedStore: () -> @toStore(ledger.storage.sync)

  removeFromStore: (store) -> store.remove(["__m2fa_#{@id}"])

  removeFromSyncedStore: -> @removeFromStore(ledger.storage.sync)

  @fromStore: (id, store, callback = _.noop) ->
    closure = new CompletionClosure()
    closure.onComplete callback
    store.get "__m2fa_#{id}", (objects) ->
      result = if objects.length > 0 then new @(objects[0]) else null
      error = if objects.length is 0 then ledger.errors.NotFound else null
      closure.complete(result, error)
    closure.readonly()

  @fromSyncedStore: (id, callback = _.noop) -> @fromStore(id, ledger.storage.sync, callback)

  @create: (id, data) -> new @(id: id, name: data['name'], created_at: new Date().getTime(), uuid: data['uuid'], platform: data['platform'], version: VERSION)

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
      return closure.failure(ledger.errors.NotFound) if screens.length is 0
      closure.success(_(screens).max (screen) -> screen.createdAt.getTime())
    closure.readonly()

  @getMostRecentFromSyncedStore: (callback = _.noop) -> @getMostRecentFromStore(ledger.storage.sync, callback)

  @getByNameFromStore: (store, name, callback = _.noop) ->
    closure = new CompletionClosure(callback)
    @getAllFromStore store, (result, error) ->
      return closure.failure(error) if error?
      closure.success(_(result).where(name: name)[0])
    closure.readonly()

  @getByNameFromSyncedStore: (name, callback = _.noop) -> @getByNameFromStore(ledger.storage.sync, name, callback)

  @getAllGroupedByPropertyFromStore: (store, property, callback = _.noop) ->
    closure = new CompletionClosure(callback)
    @getAllFromStore store, (screens, error) ->
      return closure.failure(error) if error?
      groups = _.groupBy screens, (s) -> s[property]
      closure.success(groups)
    closure.readonly()

  @getAllGroupedByPropertyFromSyncedStore: (property, callback = _.noop) -> @getAllGroupedByPropertyFromStore(ledger.storage.sync, property, callback)

  @getAllGroupedByUuidFromStore: (store, callback = _.noop) -> @getAllGroupedByPropertyFromStore(store, 'uuid', callback)

  @getAllGroupedByUuidFromSyncedStore: (callback = _.noop) -> @getAllGroupedByUuidFromStore(ledger.storage.sync, callback)

  @getScreensByUuidFromStore: (store, uuid, callback = _.noop) ->
    closure = new CompletionClosure(callback)
    @getAllFromStore store, (result, error) ->
      return closure.failure(error) if error?
      closure.success(_(result).where(uuid: uuid))
    closure.readonly()

  @getScreensByUuidFromSyncedStore: (uuid, callback = _.noop) -> @getScreensByUuidFromStore(ledger.storage.sync, uuid, callback)

  @removePairedSecureScreensFromStore: (store, screens, callback = _.noop) ->
    store.remove ("__m2fa_#{screen.id}" for screen in screens), callback

  @removePairedSecureScreensFromSyncedStore: (screens, callback) -> @removePairedSecureScreensFromStore(ledger.storage.sync, screens, callback)

  @removePairedSecureScreensByUuidFromStore: (store, uuid, callback = _.noop) ->
    @getScreensByUuidFromStore store, uuid, (screens, error) =>
      return callback(null, error) if error?
      @removePairedSecureScreensFromStore(store, screens, callback)

  @removePairedSecureScreensByUuidFromSyncedStore: (uuid, callback = _.noop) -> @removePairedSecureScreensByUuidFromStore(ledger.storage.sync, uuid, callback)