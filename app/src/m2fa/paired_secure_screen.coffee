
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

  @fromStore: (id, store, callback=undefined) ->
    d = ledger.defer(callback)
    store.get "__m2fa_#{id}", (objects) ->
      if objects.length > 0
        d.resolve(new @(objects[0]))
      else
        d.reject(ledger.errors.NotFound)
    d.promise

  @fromSyncedStore: (id, callback=undefined) -> @fromStore(id, ledger.storage.sync, callback)

  @create: (id, data) -> new @(id: id, name: data['name'], created_at: new Date().getTime(), uuid: data['uuid'], platform: data['platform'], version: VERSION)

  @getAllFromStore: (store, callback=undefined) ->
    d = ledger.defer(callback)
    store.keys (keys) =>
      keys = _.filter(keys, (key) -> key.match(/^__m2fa_/))
      return d.resolve([]) if keys.length is 0
      store.get keys, (objects) =>
        screens = (new @(object) for k, object of objects)
        d.resolve(screens)
    d.promise

  @getAllFromSyncedStore: (callback=undefined) -> @getAllFromStore(ledger.storage.sync, callback)

  @getMostRecentFromStore: (store, callback=undefined) ->
    defer = ledger.defer(callback)
    p = @getAllFromStore(store).then (screens) ->
      throw ledger.errors.new(ledger.errors.NotFound) if screens.length is 0
      _(screens).max (screen) -> screen.createdAt.getTime()
    defer.resolve(p).promise

  @getMostRecentFromSyncedStore: (callback=undefined) -> @getMostRecentFromStore(ledger.storage.sync, callback)

  @getByNameFromStore: (store, name, callback=undefined) ->
    defer = ledger.defer(callback)
    p = @getAllFromStore(store).then (results) -> _(results).where(name: name)[0] || null
    defer.resolve(p).promise

  @getByNameFromSyncedStore: (name, callback=undefined) -> @getByNameFromStore(ledger.storage.sync, name, callback)

  @getAllGroupedByPropertyFromStore: (store, property, callback=undefined) ->
    defer = ledger.defer(callback)
    p = @getAllFromStore(store).then (screens) -> _.groupBy screens, (s) -> s[property]
    defer.resolve(p).promise

  @getAllGroupedByPropertyFromSyncedStore: (property, callback=undefined) -> @getAllGroupedByPropertyFromStore(ledger.storage.sync, property, callback)

  @getAllGroupedByUuidFromStore: (store, callback=undefined) -> @getAllGroupedByPropertyFromStore(store, 'uuid', callback)

  @getAllGroupedByUuidFromSyncedStore: (callback=undefined) -> @getAllGroupedByUuidFromStore(ledger.storage.sync, callback)

  @getScreensByUuidFromStore: (store, uuid, callback=undefined) ->
    defer = ledger.defer(callback)
    p = @getAllFromStore(store).then (results) -> _(results).where(uuid: uuid)
    defer.resolve(p).promise

  @getScreensByUuidFromSyncedStore: (uuid, callback=undefined) -> @getScreensByUuidFromStore(ledger.storage.sync, uuid, callback)

  @removePairedSecureScreensFromStore: (store, screens, callback=undefined) ->
    store.remove ("__m2fa_#{screen.id}" for screen in screens), callback

  @removePairedSecureScreensFromSyncedStore: (screens, callback) -> @removePairedSecureScreensFromStore(ledger.storage.sync, screens, callback)

  @removePairedSecureScreensByUuidFromStore: (store, uuid, callback=undefined) ->
    @getScreensByUuidFromStore(store, uuid)
    .catch (error) -> callback?(false, error); throw error
    .then (screens) => @removePairedSecureScreensFromStore(store, screens, callback)

  @removePairedSecureScreensByUuidFromSyncedStore: (uuid, callback=undefined) -> @removePairedSecureScreensByUuidFromStore(ledger.storage.sync, uuid, callback)
