@ledger.storage ?= {}

@ledger.storage.closeStores = ->
  delete ledger.storage.local
  delete  ledger.storage.sync

@ledger.storage.openStores = (passphrase) ->
  localStorage = new ledger.storage.SecureStore 'ledger.local', passphrase
  ledger.storage.local =  new ledger.storage.IndexedStore localStorage
  ledger.storage.sync = new ledger.storage.SyncedStore('ledger.meta', 'invalidpassword')


