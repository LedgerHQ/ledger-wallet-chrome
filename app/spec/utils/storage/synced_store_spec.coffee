describe "SyncedStore", ->
  store = null
  obj =
    cb: ->

  beforeEach ->
    spyOn(_, 'defer')
    store = new ledger.storage.SyncedStore("synced_store", "private_key")
    store.client = jasmine.createSpyObj('restClient', ['get_settings_md5','get_settings','post_settings','put_settings','delete_settings'])

  it "call debounced push when a value is set", ->
    spyOn(ledger.storage.SecureStore.prototype, 'set').and.callFake (items, cb) -> cb()
    spyOn(store, 'debounced_push')
    store.set()

    expect(ledger.storage.SecureStore.prototype.set).toHaveBeenCalled()
    expect(store.debounced_push).toHaveBeenCalled()

  it "call debounced push when a value is removed", ->
    spyOn(ledger.storage.SecureStore.prototype, 'remove').and.callFake (items, cb) -> cb()
    spyOn(store, 'debounced_push')
    store.remove()

    expect(ledger.storage.SecureStore.prototype.remove).toHaveBeenCalled()
    expect(store.debounced_push).toHaveBeenCalled()

  it "call client.delete_settings on clear", ->
    store.clear()
    expect(store.client.delete_settings).toHaveBeenCalled()
