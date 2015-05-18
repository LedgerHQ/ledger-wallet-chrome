describe "SyncedStore", ->
  store = null
  obj =
    cb: ->

  beforeEach (done) ->
    store = new ledger.storage.SyncedStore("synced_store", "specs", "private_key", new ledger.storage.MemoryStore("specs"))
    store.client = jasmine.createSpyObj('restClient', ['get_settings_md5','get_settings','post_settings','put_settings','delete_settings'])
    _.defer -> do done

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

  it "returns the value just set", (done) ->
    store.client.get_settings_md5.and.callFake -> Q.defer().promise
    store.set foo: 'bar', ->
      store.get ['foo'], (result) ->
        expect(result['foo']).toBe('bar')
        do done

  it "returns no value when it has been removed", (done) ->
    store.client.get_settings_md5.and.callFake -> Q.defer().promise
    store.set foo: 'bar', ->
      store.remove ['foo'], ->
        store.get ['foo'], (result) ->
          expect(result['foo']).toBe(undefined)
          do done

  it "push when there is data on server side", (done) ->
    store.client.get_settings_md5.and.callFake -> ledger.defer().reject({status: 404}).promise
