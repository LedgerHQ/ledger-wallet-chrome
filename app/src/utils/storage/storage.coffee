@ledger.storage ?= {}

@ledger.storage.local = new ledger.storage.SecureStore('ledger.local', 'invalidpassword')
@ledger.storage.sync = new ledger.storage.SyncedStore('ledger.meta', 'invalidpassword')

