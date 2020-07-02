@ledger.storage ?= {}

@ledger.storage.openStores = (bitIdAddress, passphrase) ->
  localStorage = new ledger.storage.SecureStore 'ledger.local.' + bitIdAddress + ledger.config.network.name, passphrase
  ledger.storage.wallet = new ledger.storage.SecureStore 'ledger.wallet.v2' + bitIdAddress + ledger.config.network.name, passphrase
  ledger.storage.local = new ledger.storage.SecureStore 'ledger.local.' + bitIdAddress + ledger.config.network.name, passphrase
  ledger.storage.databases = new ledger.storage.SecureStore 'ledger.database.' + bitIdAddress + ledger.config.network.name, passphrase
  ledger.storage.logs = new ledger.storage.SecureStore 'ledger.logs' + bitIdAddress + ledger.config.network.name, passphrase
  ledger.storage.sync = new ledger.storage.SyncedStore('ledger.meta.' + bitIdAddress  + ledger.config.network.name, bitIdAddress, passphrase)
  ledger.storage.sync.wallet = ledger.storage.sync.substore("wallet_layout"+ bitIdAddress + ledger.config.network.name)
  ledger.storage.logs.clear() # TODO: Remove this later (Crappy 'fix' for slow logger)

@ledger.storage.closeStores = () ->
  for key, storage of ledger.storage when _(storage).isKindOf(ledger.storage.Store)
    storage.close()
    ledger.storage[key] = null

@ledger.storage.global = {}
@ledger.storage.global.chainSelector = new ledger.storage.ChromeStore("chainSelector")
@ledger.storage.global.live = new ledger.storage.ChromeStore("live")
