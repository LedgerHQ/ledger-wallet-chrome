originalTimeout = jasmine.DEFAULT_TIMEOUT_INTERVAL
jasmine.DEFAULT_TIMEOUT_INTERVAL = 50000


describe "WalletLayoutRecoveryTask", ->

  task = new ledger.tasks.WalletLayoutRecoveryTask()
  task?.constructor.stopAllRunningTasks()

  init = (pin, seed, pairingKey, done) ->
    chrome.storage.local.clear()
    ledger.tasks.AddressDerivationTask.instance.start()
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
          task.start()
          task.on 'stop', -> done()



  xdescribe " - zero account", ->
    beforeAll (done) ->
      spyOn(task, '_restoreChronocoinLayout')
      dongle = ledger.specs.fixtures.dongles.dongle2
      init dongle.pin, dongle.masterSeed, dongle.pairingKeyHex, done

    it "should call restoreChronocoinLayout", (done) ->
      expect(task._restoreChronocoinLayout).toHaveBeenCalled()
      done()

    afterAll ->
      task.constructor.stopAllRunningTasks()
      chrome.storage.local.clear()
      @dongleInst = null



  describe " - seed with one empty account", ->
    beforeAll (done) ->
      dongle = ledger.specs.fixtures.dongles.dongle2
      init dongle.pin, dongle.masterSeed, dongle.pairingKeyHex, done

    it "should have 1 account", ->
      expect(typeof ledger.wallet.Wallet.instance.getAccount(0)).toBe('object')
      expect(ledger.wallet.Wallet.instance.getAccount(1)).toBeUndefined()

    it "should have 0 address in internal and external nodes", ->
      expect(ledger.wallet.Wallet.instance.getAccount(0).getCurrentChangeAddressIndex()).toBe(0)
      expect(ledger.wallet.Wallet.instance.getAccount(0).getCurrentPublicAddressIndex()).toBe(0)

    afterAll ->
      task.constructor.stopAllRunningTasks()
      chrome.storage.local.clear()
      @dongleInst = null



  describe " - seed with two accounts", ->
    beforeAll (done) ->
      #spyOn(task, '_restoreBip44Layout')
      dongle = ledger.specs.fixtures.dongles.dongle1
      init dongle.pin, dongle.masterSeed, dongle.pairingKeyHex, done

    it "should have 2 accounts", ->
      l 'ledger.wallet.Wallet.instance', ledger.wallet.Wallet.instance.getAccount(1)
      expect(typeof ledger.wallet.Wallet.instance.getAccount(0)).toBe('object')
      expect(typeof ledger.wallet.Wallet.instance.getAccount(1)).toBe('object')
      expect(ledger.wallet.Wallet.instance.getAccount(2)).toBeUndefined()
      #expect(task._restoreBip44Layout).toHaveBeenCalled()

    it "first account should have 7 addresses in internal nodes and 31 in external nodes", ->
      expect(ledger.wallet.Wallet.instance.getAccount(0).getCurrentChangeAddressIndex()).toBe(7)
      expect(ledger.wallet.Wallet.instance.getAccount(0).getCurrentPublicAddressIndex()).toBe(31)

    it "should have importedChangePaths and importedPublicPaths", ->
      expect(ledger.wallet.Wallet.instance.getAccount(0).getAllChangeAddressesPaths()).toContain("0'/1/0")
      expect(ledger.wallet.Wallet.instance.getAccount(0).getAllPublicAddressesPaths()).toContain("0'/0/0")

    afterAll ->
      chrome.storage.local.clear()
      task.constructor.stopAllRunningTasks()
      @dongleInst = null


  afterAll ->
    jasmine.DEFAULT_TIMEOUT_INTERVAL = originalTimeout







