describe "Extended public key", ->

  xpubInstance = null
  dongleInst   = null

  init = (pin, seed, pairingKey, callback) ->
    chrome.storage.local.clear()
    dongleInst = new ledger.dongle.MockDongle pin, seed, pairingKey
    ledger.app.dongle = dongleInst
    dongleInst.unlockWithPinCode '0000', callback


  beforeAll (done) ->
    dongle = ledger.specs.fixtures.dongles.dongle1
    init dongle.pin, dongle.masterSeed, dongle.pairingKeyHex, ->
      xpubInstance = new ledger.wallet.ExtendedPublicKey(ledger.app.dongle, "44'/0'/0'", false)
      xpubInstance.initialize(done)


  it "should create an xPub", (done) ->
    expect(xpubInstance._xpub58).toBe('xpub6DCi5iJ57ZPd5qPzvTm5hUt6X23TJdh9H4NjNsNbt7t7UuTMJfawQWsdWRFhfLwkiMkB1rQ4ZJWLB9YBnzR7kbs9N8b2PsKZgKUHQm1X4or')
    done()

  it "should get the first public address", (done) ->
    expect(xpubInstance.getPublicAddress("0/0")).toBe('151krzHgfkNoH3XHBzEVi6tSn4db7pVjmR')
    done()


  afterAll ->
    chrome.storage.local.clear()
    dongleInst = null