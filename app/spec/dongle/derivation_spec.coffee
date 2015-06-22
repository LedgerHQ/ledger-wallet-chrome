describe 'Hardware and Software derivations', ->

  PinCode = '0000'

  it 'compute the same address', (done) ->
    ledger.app.dongle.lock()
    ledger.app.dongle.unlockWithPinCode(PinCode)
    .then ->
      ledger.app.dongle.getPublicAddress("44'/0'/0'/1/84")
    .then (address) ->
      expect(address.bitcoinAddress.toString(ASCII)).toBe('1PCbsXooZxknnX8p9kpUZeedYRbTGUTsSL')
      done()
    .done()