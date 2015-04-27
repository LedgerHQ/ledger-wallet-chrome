
ledger.print ?= {}

class ledger.print.Piper

  _chromeStore: new ledger.storage.ChromeStore('piper')
  @instance: new @()


  setIP: (IP) ->
    @_chromeStore.set({__piper_IP: IP})


  setPubKey: (pubKey) ->
    @_chromeStore.set({__piper_pubKey: pubKey})


  getIP: (cb) ->
    @_chromeStore.get '__piper_IP', (r) =>
      cb?(r.__piper_IP)

  getPubKey: (cb) ->
    @_chromeStore.get '__piper_pubKey', (r) =>
      cb?(r.__piper_pubKey)

  printMnemonic: (mnemonic) ->
    @getIP (IP) =>
      @getPubKey (pubKey) =>
        l IP, pubKey



