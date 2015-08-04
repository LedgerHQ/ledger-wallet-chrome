@ledger.storage ?= {}

@ledger.storage.openStores = (bitIdAddress, passphrase) ->
  localStorage = new ledger.storage.SecureStore 'ledger.local.' + bitIdAddress, passphrase
  ledger.storage.wallet = new ledger.storage.SecureStore 'ledger.wallet.' + bitIdAddress, passphrase
  ledger.storage.databases = new ledger.storage.SecureStore 'ledger.database.' + bitIdAddress, passphrase
  ledger.storage.logs = new ledger.storage.SecureStore 'ledger.logs' + bitIdAddress, passphrase
  ledger.storage.sync = new ledger.storage.SyncedStore('ledger.meta.' + bitIdAddress, bitIdAddress, passphrase)
  ledger.storage.sync.wallet = ledger.storage.sync.substore("wallet_layout")
  ledger.storage.logs.clear() # TODO: Remove this later (Crappy 'fix' for slow logger)

@ledger.storage.closeStores = () ->
  ledger.storage.sync = null
  ledger.storage.wallet = null
  ledger.storage.databases = null
  ledger.storage.logs = null


unless chrome?.storage?.local?
  ((@chrome ||= {}).storage ||= {}).local ||= {}

  _.extend chrome.storage.local,

    get: (keys, cb) ->
      result = {}
      result[k] = v for k, v of localStorage when keys is null or _(keys).contains(k)
      _.defer -> cb?(result)

    set: (data, cb) ->
      localStorage.setItem(k, v) for k, v of data
      _.defer -> cb?(data)

    remove: (keys, cb) ->
      localStorage.removeItem(k) for k in keys
      _.defer -> cb?(keys)

    clear: (cb) ->
      localStorage.removeItem(k) for k in localStorage
      _.defer -> cb?()

