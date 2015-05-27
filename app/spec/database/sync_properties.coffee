describe "Database synchronized properties", ->

  store = null
  sync = null
  db = null
  context = null

  beforeEach (done) ->
    store = new ledger.storage.MemoryStore()
    sync = new ledger.storage.MemoryStore()
    db = new ledger.database.Database('specs', store)
    db.load ->
      context = new ledger.database.contexts.Context(db, sync)
      do done

  it 'updates existing objects', (done) ->
    Account.create({index: 0, name: "My Spec Account"}, context).save()
    context.on 'insert:account', ->
      sync.substore('sync_account_0').set index: 0, name: "My Sync Spec Account", ->
        sync.emit 'pulled'
        context.on 'update:account insert:account', ->
          [account] = Account.find(index: 0, context).data()
          expect(account.get('name')).toBe("My Sync Spec Account")
          do done

  it 'creates missing objects', (done) ->
    sync.substore('sync_account_0').set index: 0, name: "My Sync Spec Account", ->
      sync.emit 'pulled'
      context.on 'update:account insert:account', ->
        [account] = Account.find(index: 0, context).data()
        expect(account.get('name')).toBe("My Sync Spec Account")
        do done

  it 'creates data on sync store when an object is inserted', (done) ->


  it 'updates sync store when an object is saved', (done) ->

  it 'deletes data from sync store when an object is deleted', (done) ->

  it 'restores relationships', (done) ->

