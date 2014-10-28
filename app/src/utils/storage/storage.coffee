@ledger.storage ?= {}

@ledger.storage.local = new @ledger.storage.PersistentStore('ledger-wallet-local-store')
@ledger.storage.sync = new @ledger.storage.Store('ledger-wallet-sync-store')