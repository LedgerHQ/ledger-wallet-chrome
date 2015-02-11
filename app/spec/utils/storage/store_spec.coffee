describe "Store", ->
  store = null
  obj =
    cb: ->

  beforeEach ->
    store = new ledger.storage.Store("a.pretty.ns")
  
  it "transform key to namespaced key", ->
    expect(store._to_ns_key("key")).toBe("a.pretty.ns.key")
  
  it "transform keys to namespaced keys", ->
    expect(store._to_ns_keys(["key1", "key2"])).toEqual(["a.pretty.ns.key1", "a.pretty.ns.key2"])
  
  it "transform namespaced key to key", ->
    expect(store._from_ns_key("a.pretty.ns.key")).toBe("key")
  
  it "transform namespaced keys to keys", ->
    expect(store._from_ns_keys(["a.pretty.ns.key1", "a.pretty.ns.key2"])).toEqual(["key1", "key2"])

  it "filter namespaced keys", ->
    expect(store._from_ns_keys(["a.pretty.ns.key1", "an.other.ns.key2"])).toEqual(["key1"])
  
  it "preprocess key should namespace key", ->
    expect(store._preprocessKey("key")).toBe("a.pretty.ns.key")
  
  it "preprocess keys should preprocess each key", ->
    expect(store._preprocessKeys(["key1", "key2"])).toEqual(["a.pretty.ns.key1", "a.pretty.ns.key2"])
  
  it "preprocess value should stringify to JSON", ->
    expect(store._preprocessValue([1,2,3])).toBe("[1,2,3]")
  
  it "preprocess items should preprocess keys and values", ->
    expect(store._preprocessItems(key: [1,2,3])).toEqual("a.pretty.ns.key":"[1,2,3]")
  
  it "filter falsy keys and function values during items preprocess", ->
    expect(store._preprocessItems(key: 42, "": 1, undefined: 2, null: 3)).toEqual("a.pretty.ns.key":"42")
  
  it "deprocess key should slice namespace", ->
    expect(store._deprocessKey("a.pretty.ns.key")).toBe("key")
  
  it "deprocess keys should deprocess each key", ->
    expect(store._deprocessKeys(["a.pretty.ns.key1", "a.pretty.ns.key2"])).toEqual(["key1", "key2"])
  
  it "deprocess keys should skip bad keys", ->
    expect(store._deprocessKeys(["a.pretty.ns.key1", "a.pretty.ns.key2"])).toEqual(["key1", "key2"])

  it "deprocess value should parse JSON", ->
    expect(store._deprocessValue("[1,2,3]")).toEqual([1,2,3])
  
  it "deprocess items should deprocess keys and values", ->
    expect(store._deprocessItems("a.pretty.ns.key":"[1,2,3]")).toEqual(key: [1,2,3])

  it "calls _raw_set with preprocessed items on set", ->
    spyOn(store, '_raw_set').and.callFake((raw_items, cb)-> cb())
    spyOn(obj, 'cb')

    store.set({key: 42}, obj.cb)
    expect(store._raw_set.calls.count()).toBe(1)
    expect(store._raw_set.calls.argsFor(0)[0]).toEqual("a.pretty.ns.key":"42")
    expect(obj.cb).toHaveBeenCalled()

  it "#get calls _raw_get with preprocessed keys", ->
    spy = spyOn(store, '_raw_get').and.callFake (raw_keys, cb) -> cb("a.pretty.ns.key":"42")
    spyOn(obj, 'cb')

    store.get("key", obj.cb)
    expect(store._raw_get.calls.count()).toBe(1)
    expect(store._raw_get.calls.argsFor(0)[0]).toEqual(["a.pretty.ns.key"])
    expect(obj.cb).toHaveBeenCalledWith(key: 42)

    spy.and.callFake (raw_keys, cb) -> cb("a.pretty.ns.key1":"1", "a.pretty.ns.key2":"2")

    store.get(["key1", "key2"], obj.cb)
    expect(store._raw_get.calls.argsFor(1)[0]).toEqual(["a.pretty.ns.key1", "a.pretty.ns.key2"])
    expect(obj.cb).toHaveBeenCalledWith(key1: 1, key2: 2)

  it "#keys calls _raw_keys", ->
    spyOn(store, '_raw_keys').and.callFake (cb)-> cb(["a.pretty.ns.key1", "a.pretty.ns.key2"])
    spyOn(obj, 'cb')

    store.keys(obj.cb)
    expect(store._raw_keys).toHaveBeenCalled()
    expect(obj.cb).toHaveBeenCalledWith(["key1", "key2"])

  it "#keys filter bad keys", ->
    spyOn(store, '_raw_keys').and.callFake (cb)-> cb(["a.pretty.ns.key1", "a.other.ns.key2"])
    spyOn(obj, 'cb')

    store.keys(obj.cb)
    expect(store._raw_keys).toHaveBeenCalled()
    expect(obj.cb).toHaveBeenCalledWith(["key1"])

  it "#remove calls _raw_remove with preprocessed keys", ->
    spy = spyOn(store, '_raw_remove').and.callFake (raw_keys, cb)-> cb("a.pretty.ns.key":"42")
    spyOn(obj, 'cb')

    store.remove("key", obj.cb)
    expect(store._raw_remove.calls.count()).toBe(1)
    expect(store._raw_remove.calls.argsFor(0)[0]).toEqual(["a.pretty.ns.key"])
    expect(obj.cb).toHaveBeenCalledWith(key: 42)

    spy.and.callFake (raw_keys, cb)-> cb("a.pretty.ns.key1":"1", "a.pretty.ns.key2":"2")
    store.remove(["key1", "key2"], obj.cb)
    expect(store._raw_remove.calls.argsFor(1)[0]).toEqual(["a.pretty.ns.key1", "a.pretty.ns.key2"])
    expect(obj.cb).toHaveBeenCalledWith(key1: 1, key2: 2)

  it "#clear calls _raw_keys and _raw_remove", ->
    spyOn(store, '_raw_keys').and.callFake (cb)-> cb(["a.pretty.ns.key1", "a.pretty.ns.key2"])
    spyOn(store, '_raw_remove').and.callFake (raw_keys, cb)-> cb("a.pretty.ns.key1":"1", "a.pretty.ns.key2":"2")
    spyOn(obj, 'cb')

    store.clear(obj.cb)
    expect(store._raw_keys).toHaveBeenCalled()
    expect(store._raw_remove.calls.count()).toBe(1)
    expect(store._raw_remove.calls.argsFor(0)[0]).toEqual(["a.pretty.ns.key1", "a.pretty.ns.key2"])
    expect(obj.cb).toHaveBeenCalledWith(key1: 1, key2: 2)
