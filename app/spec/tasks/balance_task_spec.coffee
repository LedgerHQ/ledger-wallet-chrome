describe "BalanceTask", ->

  originalTimeout = jasmine.DEFAULT_TIMEOUT_INTERVAL
  dongleInst = null

  init = (pin, seed, pairingKey, callback) ->
    dongleInst = new ledger.dongle.MockDongle pin, seed, pairingKey
    ledger.app.dongle = dongleInst
    dongleInst.unlockWithPinCode '0000', callback

  beforeEach (done) ->
    jasmine.DEFAULT_TIMEOUT_INTERVAL = 300000 # Cache is not used, please wait...
    ledger.tasks.Task.stopAllRunningTasks()
    ledger.tasks.Task.resetAllSingletonTasks()
    ledger.storage.databases = new ledger.storage.MemoryStore("databases")
    ledger.storage.wallet = new ledger.storage.MemoryStore("wallet")
    ledger.storage.sync = new ledger.storage.MemoryStore("sync")
    ledger.storage.sync.wallet = ledger.storage.sync.substore("wallet_layout")
    ledger.wallet.initialize dongleInst, ->
      ledger.database.init ->
        ledger.database.contexts.open()
        Wallet.instance = Wallet.findOrCreate(1, {id: 1}).save()
        acc = Account.findOrCreate(index: 0).save()
        acc.set('wallet', Wallet.instance).save()
        ledger.wallet.Wallet.instance.createAccount()
        ledger.tasks.AddressDerivationTask.instance.start()
        dongle = ledger.specs.fixtures.dongles.dongle1
        init dongle.pin, dongle.masterSeed, dongle.pairingKeyHex, done

  it "should get account balance", (done) ->
    accountIndex = 0
    ledger.tasks.BalanceTask.get(accountIndex).start()
    balanceTask = ledger.tasks.BalanceTask.get(accountIndex)
    balanceTask.getAccountBalance()
    account = Account.find(index: accountIndex).first()
    ledger.app.once 'wallet:balance:changed wallet:balance:unchanged', ->
      expect(account.get('wallet').getBalance().wallet.total).toBe(0)
      done()


  afterEach (done) ->
    [ledger.storage.databases, ledger.storage.wallet, ledger.storage.sync, ledger.storage.sync.wallet].forEach (that) -> that.clear()
    ledger.tasks.Task.stopAllRunningTasks()
    ledger.tasks.Task.resetAllSingletonTasks()
    jasmine.DEFAULT_TIMEOUT_INTERVAL = originalTimeout
    _.defer -> done()