describe "WalletLayoutRecoveryTask", ->

  task = new ledger.tasks.WalletLayoutRecoveryTask()

  describe " - seed with one empty account", ->

    beforeAll (done) ->
      task?.constructor.stopAllRunningTasks()
      dongle1account = ledger.specs.fixtures.dongles.dongle2
      dongleInst = new ledger.dongle.MockDongle dongle1account.pin, dongle1account.masterSeed, dongle1account.pairingKeyHex
      dongleInst.unlockWithPinCode('0000')
      ledger.app.dongle = dongleInst
      ledger.bitcoin.bitid.getAddress (address) =>
        bitIdAddress = address.bitcoinAddress.toString(ASCII)
        dongleInst.getPublicAddress "0x50DA'/0xBED'/0xC0FFEE'", (pubKey) =>
          if not (pubKey?.bitcoinAddress?) or not (bitIdAddress?)
            logger().error("Fatal error during openStores, missing bitIdAddress and/or pubKey.bitcoinAddress")
            raise(ledger.errors.new(ledger.errors.UnableToRetrieveBitidAddress))
            ledger.app.emit 'wallet:initialization:fatal_error'
            return
          ledger.storage.openStores bitIdAddress, pubKey.bitcoinAddress.value
          task.start.bind(task)
          ledger.wallet.initialize(dongleInst, done)


    fit "should have 1 account", ->
      ledger.tasks.AddressDerivationTask.instance.onStart()

      #l ledger.wallet.Wallet.instance
      expect(typeof ledger.wallet.Wallet.instance.getAccount(0)).toBe('object')
      expect(ledger.wallet.Wallet.instance.getAccount(1)).toBeUndefined()
      spyOn ledger.tasks.WalletLayoutRecoveryTask.instance, '_restoreChronocoinLayout'
      expect(ledger.tasks.WalletLayoutRecoveryTask.instance._restoreChronocoinLayout).toHaveBeenCalled()


    it "should have 0 address in internal and external nodes", ->
      expect(ledger.wallet.Wallet.instance.getAccount(0).getCurrentChangeAddressIndex()).toBe(0)
      expect(ledger.wallet.Wallet.instance.getAccount(0).getCurrentPublicAddressIndex()).toBe(0)


    afterAll (done) ->
      task.constructor.stopAllRunningTasks()
      #@dongleInst = null
      done()


  describe " - seed with two accounts", ->

    beforeAll ->
      task.constructor.stopAllRunningTasks()
      dongle2accounts = ledger.specs.fixtures.dongles.dongle1
      dongleInst = new ledger.dongle.MockDongle dongle2accounts.pin, dongle2accounts.masterSeed, dongle2accounts.pairingKeyHex
      _event = new EventEmitter
      _event.emit 'connected', dongleInst
      dongleInst.unlockWithPinCode('0000')
      task.start()

    it "should have 2 accounts", (done) ->
      task.once 'start', (event) ->
        expect(ledger.wallet.Wallet.instance.isInitialized).toBeTruthy()
        expect(ledger.wallet.Wallet.instance.getAccount(0)).toBe(typeof 'object')
        expect(ledger.wallet.Wallet.instance.getAccount(1)).toBe(typeof 'object')
        expect(ledger.wallet.Wallet.instance.getAccount(2)).toBeUndefined()
        expect(ledger.tasks.WalletLayoutRecoveryTask.instance._restoreBip44Layout()).toHaveBeenCalled()
        done()

    it "first account should have 7 addresses in internal nodes and 31 in external nodes", ->
      expect(ledger.wallet.Wallet.instance.getAccount(0).getCurrentChangeAddressIndex()).toBe(7)
      expect(ledger.wallet.Wallet.instance.getAccount(0).getCurrentPublicAddressIndex()).toBe(31)

    it "should have importedChangePaths and importedPublicPaths", ->
      expect(ledger.wallet.Wallet.instance.getAccount(0).getAllChangeAddressesPaths()).toContain("0'/1/0")
      expect(ledger.wallet.Wallet.instance.getAccount(0).getAllPublicAddressesPaths()).toContain("0'/0/0")

    afterAll ->
      task.constructor.stopAllRunningTasks()
      #@dongleInst = null