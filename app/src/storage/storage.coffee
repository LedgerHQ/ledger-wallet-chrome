@ledger.storage ?= {}

@ledger.storage.openStores = (bitIdAddress, passphrase) ->
  localStorage = new ledger.storage.SecureStore 'ledger.local.' + bitIdAddress, passphrase
  ledger.storage.wallet = new ledger.storage.SecureStore 'ledger.wallet.v2' + bitIdAddress, passphrase
  ledger.storage.local = new ledger.storage.SecureStore 'ledger.local.' + bitIdAddress, passphrase
  ledger.storage.databases = new ledger.storage.SecureStore 'ledger.database.' + bitIdAddress, passphrase
  ledger.storage.logs = new ledger.storage.SecureStore 'ledger.logs' + bitIdAddress, passphrase
  ledger.storage.sync = new ledger.storage.SyncedStore('ledger.meta.' + bitIdAddress, bitIdAddress, passphrase)
  ledger.storage.sync.wallet = ledger.storage.sync.substore("wallet_layout")
  ledger.storage.logs.clear() # TODO: Remove this later (Crappy 'fix' for slow logger)

@ledger.storage.closeStores = () ->
  for key, storage of ledger.storage when _(storage).isKindOf(ledger.storage.Store)
    storage.close()
    ledger.storage[key] = null
