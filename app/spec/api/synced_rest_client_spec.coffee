describe "SyncedRestClient", ->
  client = null

  beforeEach ->
    client = new ledger.storage.SyncedRestClient.instance
