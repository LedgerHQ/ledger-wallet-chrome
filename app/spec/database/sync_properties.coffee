describe "Database synchronized properties", ->

  store = new ledger.storage.MemoryStore()
  sync = new ledger.storage.MemoryStore()
  db = new ledger.database.Database('specs', store)
  context = null

  beforeEach (done) ->
    db.load ->
      context = new ledger.database.contexts.Context(db, sync)
      do done

  it 'updates existing models', (done) ->
    Account.create({index: 0, name: "My Spec Account"}, context).save()
    sync.substore('sync_account_0').set index: 0, name: "My Sync Spec Account", ->
      sync.emit 'pulled'
      _.defer ->
        [account] = Account.find(index: 0, context).data()
        expect(account.get('name')).toBe("My Sync Spec Account")
        l Account.all(context)
        do done
