describe "AddressDerivationTask", ->

  ###
    Config de test
    ledger.app.donglesManager.createDongle('0000', 'af5920746fad1e40b2a8c7080ee40524a335f129cb374d4c6f82fd6bf3139b17191cb8c38b8e37f4003768b103479947cab1d4f68d908ae520cfe71263b2a0cd', 'a26d9f9187c250beb7be79f9eb8ff249')
  ###
  addrDerivationInstance = ledger.tasks.AddressDerivationTask.instance

  it "should get public address", (done) ->
    addrDerivationInstance.getPublicAddress "44'/0'/0'/0", (addr) ->
      expect(addr).toBe('19H1wRZdk17o3pUL2NsXqGLVTDk6DvsvyF')
      done()