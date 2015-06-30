describe "OperationsSynchronizationTask", ->

  originalTimeout = jasmine.DEFAULT_TIMEOUT_INTERVAL
  dongleInst = null
  account = null

  init = (pin, seed, pairingKey, callback) ->
    # Create dongle
    dongleInst = new ledger.dongle.MockDongle pin, seed, pairingKey
    ledger.app.dongle = dongleInst
    dongleInst.unlockWithPinCode '0000', ->
      ledger.tasks.AddressDerivationTask.instance.start()
      # Create stores
      ledger.storage.databases = new ledger.storage.MemoryStore("databases")
      ledger.storage.wallet = new ledger.storage.MemoryStore("wallet")
      ledger.storage.sync = new ledger.storage.MemoryStore("sync")
      ledger.storage.sync.wallet = ledger.storage.sync.substore("wallet_layout")
      # Init wallet
      ledger.wallet.initialize dongleInst, ->
        cache = new ledger.wallet.Wallet.Cache('ops_cache', ledger.wallet.Wallet.instance)
        cache.initialize ->
          ledger.wallet.Wallet.instance.cache = cache
          xcache = new ledger.wallet.Wallet.Cache('xpub_cache', ledger.wallet.Wallet.instance)
          xcache.initialize ->
            ledger.wallet.Wallet.instance.xpubCache = xcache
            paths = ["44'/0'/0'/1/0", "44'/0'/0'/1/1", "44'/0'/0'/1/2", "44'/0'/0'/1/3", "44'/0'/0'/1/4", "44'/0'/0'/1/5",
                     "44'/0'/0'/1/6", "44'/0'/0'/1/7", "44'/0'/0'/1/8", "44'/0'/0'/1/9", "44'/0'/0'/1/10", "44'/0'/0'/1/11",
                     "44'/0'/0'/1/12", "44'/0'/0'/1/13", "44'/0'/0'/1/14", "44'/0'/0'/1/15", "44'/0'/0'/1/16",
                     "44'/0'/0'/1/17", "44'/0'/0'/1/18", "44'/0'/0'/1/19", "44'/0'/0'/1/20", "44'/0'/0'/0/0",
                     "44'/0'/0'/0/1",
                     "44'/0'/0'/0/2", "44'/0'/0'/0/3", "44'/0'/0'/0/4", "44'/0'/0'/0/5", "44'/0'/0'/0/6", "44'/0'/0'/0/7",
                     "44'/0'/0'/0/8", "44'/0'/0'/0/9"]
            # Init DB
            ledger.database.init ->
              ledger.database.contexts.open()
              Wallet.instance = Wallet.findOrCreate(1, {id: 1}).save()
              account = Account.findOrCreate(index: 0).save()
              account.set('wallet', Wallet.instance).save()
              _.defer ->
                ledger.tasks.AddressDerivationTask.instance.registerExtendedPublicKeyForPath "44'/0'/0'", ->
                  ledger.wallet.Wallet.instance.getOrCreateAccount(0).notifyPathsAsUsed(paths)
                  # Add tx
                  txs = [ledger.specs.fixtures.dongle1_transactions.tx1,
                         ledger.specs.fixtures.dongle1_transactions.tx2,
                         ledger.specs.fixtures.dongle1_transactions.tx3,
                         ledger.specs.fixtures.dongle1_transactions.tx4]
                  _.async.each txs, (item, next) ->
                    account.addRawTransactionAndSave(item, next)
                    callback?()


  beforeEach (done) ->
    jasmine.DEFAULT_TIMEOUT_INTERVAL = 200000
    ledger.tasks.Task.stopAllRunningTasks()
    ledger.tasks.Task.resetAllSingletonTasks()
    # Launch init()
    dongle = ledger.specs.fixtures.dongles.dongle1
    init dongle.pin, dongle.masterSeed, dongle.pairingKeyHex, done


  afterEach (done) ->
    [ledger.storage.databases, ledger.storage.wallet, ledger.storage.sync, ledger.storage.sync.wallet].forEach (that) -> that.clear()
    ledger.tasks.Task.stopAllRunningTasks()
    ledger.tasks.Task.resetAllSingletonTasks()
    jasmine.DEFAULT_TIMEOUT_INTERVAL = originalTimeout
    _.defer -> done()


  it "should sync confirmation number", (done) ->
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