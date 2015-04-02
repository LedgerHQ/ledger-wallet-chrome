
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
    d = ledger.defer()
    d.onComplete callback
    store.get "__m2fa_#{id}", (objects) ->
      result = if objects.length > 0 then new @(objects[0]) else null
      error = if objects.length is 0 then ledger.errors.NotFound else null
      d.complete(result, error)
    d.promise

  @fromSyncedStore: (id, callback = _.noop) -> @fromStore(id, ledger.storage.sync, callback)

  @create: (id, data) -> new @(id: id, name: data['name'], created_at: new Date().getTime(), uuid: data['uuid'], platform: data['platform'], version: VERSION)

  @getAllFromStore: (store, callback = _.noop) ->
    d = ledger.defer()
    d.onComplete callback
    store.keys (keys) =>
      keys = _.filter(keys, (key) -> key.match(/^__m2fa_/))
      return d.resolve([]) if keys.length is 0
      store.get keys, (objects) =>
        screens = (new @(object) for k, object of objects)
        d.resolve(screens)
    d.promise

  @getAllFromSyncedStore: (callback = _.noop) -> @getAllFromStore(ledger.storage.sync, callback)

  @getMostRecentFromStore: (store, callback = _.noop) ->
    d = ledger.defer(callback)
    @getAllFromStore store, (screens) ->
      return d.rejectWithError(ledger.errors.NotFound) if screens.length is 0
      d.resolve(_(screens).max (screen) -> screen.createdAt.getTime())
    d.promise

  @getMostRecentFromSyncedStore: (callback = _.noop) -> @getMostRecentFromStore(ledger.storage.sync, callback)

  @getByNameFromStore: (store, name, callback = _.noop) ->
    d = ledger.defer(callback)
    @getAllFromStore store, (result, error) ->
      return d.reject(error) if error?
      d.resolve(_(result).where(name: name)[0])
    d.promise

  @getByNameFromSyncedStore: (name, callback = _.noop) -> @getByNameFromStore(ledger.storage.sync, name, callback)

  @getAllGroupedByPropertyFromStore: (store, property, callback = _.noop) ->
    d = ledger.defer(callback)
    @getAllFromStore store, (screens, error) ->
      return d.reject(error) if error?
      groups = _.groupBy screens, (s) -> s[property]
      d.resolve(groups)
    d.promise

  @getAllGroupedByPropertyFromSyncedStore: (property, callback = _.noop) -> @getAllGroupedByPropertyFromStore(ledger.storage.sync, property, callback)

  @getAllGroupedByUuidFromStore: (store, callback = _.noop) -> @getAllGroupedByPropertyFromStore(store, 'uuid', callback)

  @getAllGroupedByUuidFromSyncedStore: (callback = _.noop) -> @getAllGroupedByUuidFromStore(ledger.storage.sync, callback)

  @getScreensByUuidFromStore: (store, uuid, callback = _.noop) ->
    d = ledger.defer(callback)
    @getAllFromStore store, (result, error) ->
      return d.reject(error) if error?
      d.resolve(_(result).where(uuid: uuid))
    d.promise

  @getScreensByUuidFromSyncedStore: (uuid, callback = _.noop) -> @getScreensByUuidFromStore(ledger.storage.sync, uuid, callback)


