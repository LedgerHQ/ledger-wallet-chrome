describe "ChromeStore", ->
  store = null
  obj =
    cb: ->

  beforeEach ->
    store = new ledger.storage.ChromeStore("chrome_test")

  it "_raw_keys return keys from items", ->
    spyOn(chrome.storage.local, 'get').and.callFake (raw_keys, cb) -> cb(key1: 1, key2: 2)
    spyOn(obj, 'cb')

    store._raw_keys(obj.cb)
    expect(obj.cb).toHaveBeenCalledWith(["key1", "key2"])
