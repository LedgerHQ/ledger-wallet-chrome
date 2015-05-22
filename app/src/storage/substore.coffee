###
  Virtual {ledger.storage.Store} using its parent store to persist data.
###
class ledger.storage.SubStore extends ledger.storage.Store

  ###
    @param [ledger.storage.Store] parentStore The store used to persist data
    @param [String] name
  ###
  constructor: (parentStore, name) ->
    super "__" + name, '_'
    @_parentStore = parentStore

  # @see ledger.storage.Store#_raw_get
  _raw_get: (keys, cb) ->
    try
      @_parentStore.get(keys, cb)
    catch e
      console.error("chrome.storage.local.get :", e)

  # @see ledger.storage.Store#_raw_set
  _raw_set: (items, cb=->) ->
    try
      @_parentStore.set items, cb
    catch e
      console.error("chrome.storage.local.set :", e)

  # @see ledger.storage.Store#_raw_keys
  _raw_keys: (cb) ->
    @_parentStore.keys (keys) => cb(_.compact(key for key in keys when key?.match(@_nameRegex)))

  # @see ledger.storage.Store#_raw_remove
  _raw_remove: (keys, cb=->) ->
    try
      @_parentStore.remove(keys, cb)
    catch e
      console.error("chrome.storage.local.remove :", e)

  _deprocessValue: (raw_value) -> raw_value