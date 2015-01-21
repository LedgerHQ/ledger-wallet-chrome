describe "SyncedStore", ->
  store = null
  obj =
    cb: ->

  beforeEach ->
    spyOn(_, 'defer').and.callFake (cb) -> cb()
    spyOn(window, 'setInterval').and.callFake (cb) -> cb()
    spyOn(ledger.storage.SyncedStore.prototype, '_pull')
    store = new ledger.storage.SyncedStore("synced_store", "private_key")

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

  it "call throttle pull", ->
    expect(_.defer).toHaveBeenCalled()
    expect(window.setInterval).toHaveBeenCalled()
    expect(window.setInterval.calls.argsFor(0)[1]).toBe(store.PULL_INTERVAL_DELAY)
    expect(ledger.storage.SyncedStore.prototype._pull).toHaveBeenCalled()
