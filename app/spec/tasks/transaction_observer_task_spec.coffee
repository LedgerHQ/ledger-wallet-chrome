describe "TransactionObserverTask", ->

  originalTimeout = jasmine.DEFAULT_TIMEOUT_INTERVAL
  originalWS = null
  account = null

  init = (pin, seed, pairingKey, callback) ->
    dongleInst = new ledger.dongle.MockDongle pin, seed, pairingKey
    ledger.app.dongle = dongleInst
    dongleInst.unlockWithPinCode '0000', ->
      ledger.tasks.AddressDerivationTask.instance.start()
      ledger.storage.databases = new ledger.storage.MemoryStore("databases")
      ledger.storage.wallet = new ledger.storage.MemoryStore("wallet")
      ledger.storage.sync = new ledger.storage.MemoryStore("sync")
      ledger.storage.sync.wallet = ledger.storage.sync.substore("wallet_layout")
      ledger.wallet.initialize dongleInst, ->
        cache = new ledger.wallet.Wallet.Cache('ops_cache', ledger.wallet.Wallet.instance)
        cache.initialize ->
          ledger.wallet.Wallet.instance.cache = cache
          xcache = new ledger.wallet.Wallet.Cache('xpub_cache', ledger.wallet.Wallet.instance)
          xcache.initialize ->
            ledger.wallet.Wallet.instance.xpubCache = xcache
            # Init DB
            ledger.database.init ->
              ledger.database.contexts.open()
              Wallet.instance = Wallet.findOrCreate(1, {id: 1}).save()
              account = Account.findOrCreate(index: 0).save()
              account.set('wallet', Wallet.instance).save()
              ledger.wallet.Wallet.instance.createAccount()
              _.defer ->
                ledger.tasks.AddressDerivationTask.instance.registerExtendedPublicKeyForPath "44'/0'/0'", ->
                  ledger.wallet.Wallet.instance.getOrCreateAccount(0).notifyPathsAsUsed(["44'/0'/0'/0/6"])
                  ledger.wallet.pathsToAddresses ["44'/0'/0'/0/6"], ->
                    callback?()


  beforeEach (done) ->
    jasmine.DEFAULT_TIMEOUT_INTERVAL = 50000
    ledger.tasks.Task.stopAllRunningTasks()
    ledger.tasks.Task.resetAllSingletonTasks()
    originalWS = window.WebSocket
    window.WebSocket = class WebSocket
    window.WebSocket.prototype = jasmine.createSpyObj 'ws', ['send', 'close']
    # Launch init()
    dongle = ledger.specs.fixtures.dongles.dongle1
    init dongle.pin, dongle.masterSeed, dongle.pairingKeyHex, done


  afterEach (done) ->
    window.WebSocket = originalWS
    [ledger.storage.databases, ledger.storage.wallet, ledger.storage.sync, ledger.storage.sync.wallet].forEach (that) -> that.clear()
    ledger.tasks.Task.stopAllRunningTasks()
    ledger.tasks.Task.resetAllSingletonTasks()
    jasmine.DEFAULT_TIMEOUT_INTERVAL = originalTimeout
    _.defer -> done()



  it "should check if my txs are added to db", (done) ->
    ledger.tasks.TransactionObserverTask.instance.start()
    ledger.tasks.TransactionObserverTask.instance.on 'start', ->
      _.defer ->
        ledger.tasks.TransactionObserverTask.instance.newTransactionStream.onmessage
          data:
            JSON.stringify
              payload:
                type: "new-transaction"
                block_chain: "bitcoin"
                transaction: ledger.specs.fixtures.dongle1_transactions.tx1

        ledger.database.contexts.main.on 'insert:operation', ->
          res = _.isEmpty Operation.find({hash: 'aa1a80314f077bd2c0e335464f983eef56dfeb0eb65c99464a0e5dbe2c25b7dc'}).data()
          expect(res).toBeFalsy()
          done()



  it "should check if not my txs are not added to db", (done) ->
    ledger.tasks.TransactionObserverTask.instance.start()
    ledger.tasks.TransactionObserverTask.instance.on 'start', ->
      _.defer ->
        cb = {cb: -> res = _.isEmpty Operation.find({hash: 'a863b9a56c40c194c11eb9db9f3ea1f6ab472b02cc57679c50d16b4151c8a6e5'}).data()}
        spyOn cb, 'cb'
        ledger.tasks.TransactionObserverTask.instance.newTransactionStream.onmessage
          data:
            JSON.stringify
              payload:
                type: "new-transaction"
                block_chain: "bitcoin"
                transaction: ledger.specs.fixtures.dongle1_transactions.tx2

        ledger.database.contexts.main.on 'insert:operation', cb
        setTimeout ->
          expect(cb.cb).not.toHaveBeenCalled()
          done()
        , 100


  it "should update unconfirmed tx", (done) ->
    ledger.tasks.TransactionObserverTask.instance.start()
    ledger.tasks.TransactionObserverTask.instance.on 'start', ->
      _.defer ->
        spyOn ledger.tasks.OperationsSynchronizationTask.instance, 'synchronizeConfirmationNumbers'
        tx1 = _.clone ledger.specs.fixtures.dongle1_transactions.tx1
        tx1.confirmations = 0
        account.addRawTransactionAndSave tx1
        ledger.app.on 'wallet:operations:new', ->
          ledger.tasks.TransactionObserverTask.instance.newTransactionStream.onmessage
            data:
              JSON.stringify
                payload:
                  type: "new-block"
                  block_chain: "bitcoin"
                  block: ledger.specs.fixtures.dongle1_blocks.blockTx1

          setTimeout ->
            expect ledger.tasks.OperationsSynchronizationTask.instance.synchronizeConfirmationNumbers
            .toHaveBeenCalled()
            done()
          , 100