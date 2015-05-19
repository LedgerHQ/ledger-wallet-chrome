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

  it "posts when there is data on server side", (done) ->
    store.client.get_settings_md5.and.callFake -> ledger.defer().reject({status: 404}).promise
    store.client.post_settings.and.callFake (data) ->
      data = JSON.parse(data)
      expect(data['__hashes'][0]).toBe('7a38bf81f383f69433ad6e900d35b3e2385593f76a7b7ab5d4355b8ba41ee24b')
      expect(data['foo']).toBe('bar')
      do done
      ledger.defer().promise
    store.client.put_settings.and.throwError('Put settings shall not be called')
    store.set foo: 'bar'

  it "merges and puts when there is data on server side", (done) ->
    store.client.get_settings_md5.and.callFake -> ledger.defer().resolve({md5: 'f48139f3d9bfdab0b5374212e06f3994'}).promise
    store.client.post_settings.and.throwError('Post settings shall not be called')
    store.client.get_settings.and.callFake -> ledger.defer().resolve(settings: {"__hashes":["7a38bf81f383f69433ad6e900d35b3e2385593f76a7b7ab5d4355b8ba41ee24b"],"foo":"bar"}).promise
    store.client.put_settings.and.callFake (data) ->
      data = JSON.parse(data)
      expect(data['__hashes'].length).toBe(2)
      expect(data['__hashes'][0]).toBe('91442791035d968e103daf9da76fd3766d62d8a92c134bc0f7b29f849bb3a8ab')
      expect(data['response']).toBe(42)
      expect(data['foo']).toBe('bar')
      do done
      ledger.defer().promise
    store.set response: 42