@ledger.storage ?= {}

@ledger.storage.openStores = (bitIdAddress, passphrase, callback) ->
  localStorage = new ledger.storage.SecureStore 'ledger.local.' + bitIdAddress, passphrase
  ledger.storage.local =  new ledger.storage.ObjectStore localStorage
  ledger.storage.sync = new ledger.storage.SyncedStore('ledger.meta.' + bitIdAddress, bitIdAddress, passphrase)
  ledger.storage.wallet = new ledger.storage.SecureStore 'ledger.wallet.' + bitIdAddress, passphrase
  ledger.storage.databases = new ledger.storage.SecureStore 'ledger.database.' + bitIdAddress, passphrase
  callback?()

@ledger.storage.closeStores = () ->
  ledger.storage.local = null
  ledger.storage.sync = null
  ledger.storage.wallet = null


