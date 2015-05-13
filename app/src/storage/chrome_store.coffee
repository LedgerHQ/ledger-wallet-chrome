# A store able to keep persistently data with the chrome storage API
class @ledger.storage.ChromeStore extends ledger.storage.Store

  # @see ledger.storage.Store#_raw_get
  _raw_get: (keys, cb) ->
    try
      keys = null if keys? && keys.length < 1
      chrome.storage.local.get(keys, cb)
    catch e
      console.error("chrome.storage.local.get :", e)

  # @see ledger.storage.Store#_raw_set
  _raw_set: (items, cb=->) ->
    try
      chrome.storage.local.set(items, cb)
    catch e
      console.error("chrome.storage.local.set :", e)

  # @see ledger.storage.Store#_raw_keys
  _raw_keys: (cb) ->
    try
      chrome.storage.local.get(null, (raw_items) -> cb(_.keys(raw_items)))
    catch e
      console.error("chrome.storage.local.get :", e)

  # @see ledger.storage.Store#_raw_remove
  _raw_remove: (keys, cb=->) ->
    try
      chrome.storage.local.remove(keys, cb)
    catch e
      console.error("chrome.storage.local.remove :", e)
