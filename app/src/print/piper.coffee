
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
        address = @_getFirstBitcoinAddress mnemonic
        @_sendRequest IP, pubKey, address, mnemonic


  canUsePiper: (cb) ->
    @getIP (IP) =>
      @getPubKey (pubKey) =>
        cb?(IP? and pubKey?)


  _getFirstBitcoinAddress: (mnemonic) ->
    seed = ledger.bitcoin.bip39.generateSeed mnemonic
    node = bitcoin.HDNode.fromSeedHex(seed, bitcoin.networks.bitcoin)
    # Derive the key from the path
    path = "44'/0'/0'/0"
    path = path.split('/')
    for item in path
      [index, hardened] = item.split "'"
      node  = if hardened? then node.deriveHardened parseInt(index) else node = node.derive(index).derive(index)
    node.getAddress().toString()


  _encryptData: (text, pubKey) ->
    encrypt = new JSEncrypt()
    encrypt.setPublicKey(pubKey)
    encrypted = encrypt.encrypt(text)
    encrypted


  _splitData: (data, part) ->
    part = part - 1
    words = data.split(" ")
    start = part * 12
    end = start + 11
    string = ""
    space = ""
    for i in [start..end]
      string = string + space + words[i]
      space = " "
    string


  _sendRequest: (IP, pubKey, address, mnemonic) ->
    part1 = @_encryptData @_splitData(mnemonic, 1), pubKey
    part2 = @_encryptData @_splitData(mnemonic, 2), pubKey
    part3 = @_encryptData address, pubKey
    data =
      'part1': part1,
      'part2': part2,
      'part3': part3
    $.post('http://'+IP+'/piper.php', data)

