describe "WalletLayoutRecoveryTask", ->

  originalTimeout = jasmine.DEFAULT_TIMEOUT_INTERVAL
  mockTask = null
  dongleInst = null

  beforeAll ->
    jasmine.DEFAULT_TIMEOUT_INTERVAL = 150000
  afterAll ->
    jasmine.DEFAULT_TIMEOUT_INTERVAL = originalTimeout


  init = (pin, seed, pairingKey, callback) ->
    ledger.tasks.Task.stopAllRunningTasks()
    ledger.tasks.Task.resetAllSingletonTasks()
    ledger.tasks.AddressDerivationTask.instance.start()
    chrome.storage.local.clear()
    mockTask = new ledger.tasks.WalletLayoutRecoveryTask()
    spyOn(mockTask, '_restoreChronocoinLayout').and.callThrough()
    dongleInst = new ledger.dongle.MockDongle pin, seed, pairingKey
    ledger.app.dongle = dongleInst
    dongleInst.unlockWithPinCode('0000')
    ledger.bitcoin.bitid.getAddress (address) ->
      bitIdAddress = address.bitcoinAddress.toString(ASCII)
      dongleInst.getPublicAddress "0x50DA'/0xBED'/0xC0FFEE'", (pubKey) ->
        if not (pubKey?.bitcoinAddress?) or not (bitIdAddress?)
          logger().error("Fatal error during openStores, missing bitIdAddress and/or pubKey.bitcoinAddress")
          raise(ledger.errors.new(ledger.errors.UnableToRetrieveBitidAddress))
          ledger.app.emit 'wallet:initialization:fatal_error'
          return
        ledger.storage.openStores bitIdAddress, pubKey.bitcoinAddress.value
        ledger.wallet.initialize dongleInst, ->
          cache = new ledger.wallet.Wallet.Cache('xpub_cache', ledger.wallet.Wallet.instance)
          cache.initialize =>
            ledger.wallet.Wallet.instance.xpubCache = cache
          mockTask.start()
          mockTask.on 'stop', -> callback?()



  describe " - zero account", ->
    beforeEach (done) ->
      dongle = ledger.specs.fixtures.dongles.dongle2
      init dongle.pin, dongle.masterSeed, dongle.pairingKeyHex, ->
        done()

    it "should call restoreChronocoinLayout", ->
      expect(mockTask._restoreChronocoinLayout).toHaveBeenCalled()
      expect(ledger.wallet.Wallet.instance.getAccountsCount()).toBe(1)

    afterEach (done) ->
      ledger.tasks.Task.stopAllRunningTasks()
      ledger.tasks.Task.resetAllSingletonTasks()
      chrome.storage.local.clear()
      dongleInst = null
      _.defer -> done()



  describe " - seed with one empty account", ->
    beforeEach (done) ->
      dongle = ledger.specs.fixtures.dongles.dongle2
      init dongle.pin, dongle.masterSeed, dongle.pairingKeyHex, done

    it "should have 1 account", (done) ->
      expect(typeof ledger.wallet.Wallet.instance.getAccount(0)).toBe('object')
      expect(ledger.wallet.Wallet.instance.getAccount(1)).toBeUndefined()
      done()

    it "should have 0 address in internal and external nodes", (done) ->
      expect(ledger.wallet.Wallet.instance.getAccount(0).getCurrentChangeAddressIndex()).toBe(0)
      expect(ledger.wallet.Wallet.instance.getAccount(0).getCurrentPublicAddressIndex()).toBe(0)
      done()

    afterEach (done) ->
      ledger.tasks.Task.stopAllRunningTasks()
      ledger.tasks.Task.resetAllSingletonTasks()
      chrome.storage.local.clear()
      dongleInst = null
      _.defer -> done()



  describe " - seed with two accounts", ->
    beforeEach (done) ->
      #spyOn(mockTask, '_restoreBip44Layout')
      dongle = ledger.specs.fixtures.dongles.dongle1
      init dongle.pin, dongle.masterSeed, dongle.pairingKeyHex, done

    it "should have 2 accounts", (done) ->
      expect(ledger.wallet.Wallet.instance.getAccountsCount()).toBe(2)
      expect(typeof ledger.wallet.Wallet.instance.getAccount(0)).toBe('object')
      expect(typeof ledger.wallet.Wallet.instance.getAccount(1)).toBe('object')
      expect(ledger.wallet.Wallet.instance.getAccount(2)).toBeUndefined()
      #expect(mockTask._restoreBip44Layout).toHaveBeenCalled()
      done()

    it "first account should have 7 addresses in internal nodes and 31 in external nodes", (done) ->
      expect(ledger.wallet.Wallet.instance.getAccount(0).getCurrentChangeAddressIndex()).toBe(7)
      expect(ledger.wallet.Wallet.instance.getAccount(0).getCurrentPublicAddressIndex()).toBe(31)
      done()

    it "should have importedChangePaths and importedPublicPaths", (done) ->
      expect(ledger.wallet.Wallet.instance.getAccount(0).getAllChangeAddressesPaths()).toContain("0'/1/0")
      expect(ledger.wallet.Wallet.instance.getAccount(0).getAllPublicAddressesPaths()).toContain("0'/0/0")
      done()

    afterEach (done) ->
      ledger.tasks.Task.stopAllRunningTasks()
      ledger.tasks.Task.resetAllSingletonTasks()
      chrome.storage.local.clear()
      dongleInst = null
      _.defer -> done()