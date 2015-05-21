
describe "SyncedStore", ->
  store = null
  jencrypt = (obj) -> store._encryptToJson(obj)
  encrypt = (obj) -> JSON.parse(jencrypt(obj))
  decrypt = (obj) -> store._decrypt(obj)
  jdecrypt = (json) -> decrypt(JSON.parse(json))


  beforeEach (done) ->
    chrome.storage.local.clear()
    store = new ledger.storage.SyncedStore("synced_store", "specs", "private_key", new ledger.storage.MemoryStore("specs"))
    store.client = jasmine.createSpyObj('restClient', ['get_settings_md5','get_settings','post_settings','put_settings','delete_settings'])
    store.client.get_settings_md5.and.callFake -> Q.defer().promise
    _.defer -> do done

  xit "call debounced push when a value is set", ->
    spyOn(ledger.storage.SecureStore.prototype, 'set').and.callFake (items, cb) -> cb()
    spyOn(store, 'debounced_push')
    store.set()

    expect(ledger.storage.SecureStore.prototype.set).toHaveBeenCalled()
    expect(store.debounced_push).toHaveBeenCalled()

  xit "call debounced push when a value is removed", ->
    spyOn(ledger.storage.SecureStore.prototype, 'remove').and.callFake (items, cb) -> cb()
    spyOn(store, 'debounced_push')
    store.remove()

    expect(ledger.storage.SecureStore.prototype.remove).toHaveBeenCalled()
    expect(store.debounced_push).toHaveBeenCalled()

  xit "call client.delete_settings on clear", ->
    store.clear()
    expect(store.client.delete_settings).toHaveBeenCalled()

  it "returns the value just set", (done) ->
    store.set foo: 'bar', ->
      store.get ['foo'], (result) ->
        expect(result['foo']).toBe('bar')
        do done

  it "returns no value when it has been removed", (done) ->
    store.set foo: 'bar', ->
      store.remove ['foo'], ->
        store.get ['foo'], (result) ->
          expect(result['foo']).toBe(undefined)
          do done

  it "returns the keys just set", (done) ->
    store.set foo: 'bar', ->
      store.keys (keys) ->
        expect(keys).toContain('foo')
        do done

  it "doesn't return remove keys", (done) ->
    store._super().set foo: 'bar', ledger: 'wallet', ->
      store.remove ['foo'], ->
        store.keys (keys) ->
          expect(keys).toContain('ledger')
          expect(keys).not.toContain('foo')
          do done

  it "posts when there is data on server side", (done) ->
    store.client.get_settings_md5.and.callFake -> ledger.defer().reject({status: 404}).promise
    store.client.post_settings.and.callFake (data) ->
      data = jdecrypt(data)
      expect(data['__hashes'][0]).toBe('7a38bf81f383f69433ad6e900d35b3e2385593f76a7b7ab5d4355b8ba41ee24b')
      expect(data['foo']).toBe('bar')
      do done
      ledger.defer().promise
    store.client.put_settings.and.callFake -> fail('Put settings shall not be called')
    store.set foo: 'bar'

  it "merges and puts when there is data on server side", (done) ->
    store.client.get_settings_md5.and.callFake -> ledger.defer().resolve('f48139f3d9bfdab0b5374212e06f3994').promise
    store.client.post_settings.and.throwError('Post settings shall not be called')
    store.client.get_settings.and.callFake -> ledger.defer().resolve(encrypt {"__hashes":["7a38bf81f383f69433ad6e900d35b3e2385593f76a7b7ab5d4355b8ba41ee24b"],"foo":"bar"}).promise
    store.client.put_settings.and.callFake (data) ->
      data = jdecrypt(data)
      expect(data['__hashes'].length).toBe(2)
      expect(data['__hashes'][0]).toBe('64d7027314ccc697e64663e9ae203bc013bbce597b85df03ec9b2b2f7ef5201b')
      expect(data['response']).toBe(42)
      expect(data['foo']).toBe('bar')
      do done
      ledger.defer().promise
    store.set response: 42

  it "merges and puts when there is data on server side with old format", (done) ->
    store.client.get_settings_md5.and.callFake -> ledger.defer().resolve('f48139f3d9bfdab0b5374212e06f3994').promise
    store.client.post_settings.and.throwError('Post settings shall not be called')
    store.client.get_settings.and.callFake -> ledger.defer().resolve(encrypt {"foo":"bar"}).promise
    store.client.put_settings.and.callFake (data) ->
      data = jdecrypt data
      expect(data['__hashes'].length).toBe(1)
      expect(data['__hashes'][0]).toBe('504b02065ae353c2e8fac6623db7699823b9a0f99cd7b73213fbbb319b644b1b')
      expect(data['response']).toBe(42)
      expect(data['foo']).toBe('bar')
      do done
      ledger.defer().promise
    store.set response: 42

describe "SyncedStore (special case with custom store configurations)", ->

  it "doesn't pull if data are up to date", (done) ->
    store = new ledger.storage.SyncedStore("synced_store", "specs", "private_key", new ledger.storage.MemoryStore("specs"))
    store.client = jasmine.createSpyObj('restClient', ['get_settings_md5','get_settings','post_settings','put_settings','delete_settings'])
    store.client.get_settings_md5.and.callFake -> ledger.defer().resolve('f48139f3d9bfdab0b5374212e06f3994').promise
    store._lastMd5 = 'f48139f3d9bfdab0b5374212e06f3994'
    store._setLastMd5('f48139f3d9bfdab0b5374212e06f3994')
    store.client.get_settings.and.callFake -> fail("It should not pull settings if already up to date")
    _.defer ->
      store._pull().fin ->
        expect().toBeUndefined() # Jasmine needs expectations -_-
        do done

  it "has a local store ahead of remote data", (done) ->
    store = new ledger.storage.SyncedStore("synced_store", "specs", "private_key", new ledger.storage.MemoryStore("specs"))
    store.client = jasmine.createSpyObj('restClient', ['get_settings_md5','get_settings','post_settings','put_settings','delete_settings'])
    store.client.get_settings_md5.and.callFake -> ledger.defer().resolve('f48139f3d9bfdab0b5374212e06f3994').promise
    store._lastMd5 = 'f48139f3d9bfdab0b5374212e06f3994'
    store._setLastMd5('f48139f3d9bfdab0b5374212e06f3994')
    store.client.get_settings.and.callFake -> fail("It should not pull settings if already up to date")
    _.defer ->
      store._pull().fin ->
        expect().toBeUndefined() # Jasmine needs expectations -_-
        do done