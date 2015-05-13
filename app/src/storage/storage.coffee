@ledger.storage ?= {}

@ledger.storage.openStores = (bitIdAddress, passphrase) ->
  localStorage = new ledger.storage.SecureStore 'ledger.local.' + bitIdAddress, passphrase
  ledger.storage.sync = new ledger.storage.SyncedStore('ledger.meta.' + bitIdAddress, bitIdAddress, passphrase)
  ledger.storage.wallet = new ledger.storage.SecureStore 'ledger.wallet.' + bitIdAddress, passphrase
  ledger.storage.databases = new ledger.storage.SecureStore 'ledger.database.' + bitIdAddress, passphrase
  ledger.storage.logs = new ledger.storage.SecureStore 'ledger.logs' + bitIdAddress, passphrase

@ledger.storage.closeStores = () ->
  ledger.storage.sync = null
  ledger.storage.wallet = null
  ledger.storage.databases = null
  ledger.storage.logs = null
