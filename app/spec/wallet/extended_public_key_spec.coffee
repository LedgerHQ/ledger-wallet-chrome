describe "Extended public key", ->

  xpubInstance = new ledger.wallet.ExtendedPublicKey(ledger.app.dongle, "44'/0'/0'", false)

  beforeAll (done) ->
    xpubInstance.initialize(done)

  it "should create an xPub", ->
    expect(xpubInstance._xpub58).toBe('xpub6DCi5iJ57ZPd5qPzvTm5hUt6X23TJdh9H4NjNsNbt7t7UuTMJfawQWsdWRFhfLwkiMkB1rQ4ZJWLB9YBnzR7kbs9N8b2PsKZgKUHQm1X4or')

  it "should get the first public address", ->
    expect(xpubInstance.getPublicAddress("0/0")).toBe('151krzHgfkNoH3XHBzEVi6tSn4db7pVjmR')

