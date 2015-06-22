describe "AddressDerivationTask", ->

  addrDerivationInstance = ledger.tasks.AddressDerivationTask.instance

  init = (pin, seed, pairingKey, callback) ->
    chrome.storage.local.clear()
    addrDerivationInstance.start()
    dongleInst = new ledger.dongle.MockDongle pin, seed, pairingKey
    ledger.app.dongle = dongleInst
    dongleInst.unlockWithPinCode '0000', callback


  beforeAll (done) ->
    dongle = ledger.specs.fixtures.dongles.dongle1
    init dongle.pin, dongle.masterSeed, dongle.pairingKeyHex, done

  it "should get public address", (done) ->
    addrDerivationInstance.registerExtendedPublicKeyForPath "44'/0'/0'", ->
      addrDerivationInstance.getPublicAddress "44'/0'/0'/0", (addr) ->
        expect(addr).toBe('19H1wRZdk17o3pUL2NsXqGLVTDk6DvsvyF')
        done()


  afterAll ->
    ledger.tasks.Task.resetAllSingletonTasks()