@ledger.storage ?= {}

@ledger.storage.closeStores = ->
  ledger.storage.local.emit 'close'
  delete ledger.storage.local.store
  delete ledger.storage.local
  delete  ledger.storage.sync

@ledger.storage.openStores = (passphrase) ->
  localStorage = new ledger.storage.ChromeStore 'ledger.local', passphrase
  ledger.storage.local =  new ledger.storage.ObjectStore localStorage
  ledger.storage.sync = new ledger.storage.SyncedStore('ledger.meta', 'invalidpassword')
  ledger.storage.wallet = new ledger.storage.ChromeStore 'ledger.wallet', passphrase


