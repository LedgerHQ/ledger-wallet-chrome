
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
        @_canUsePiper (isPiper) =>
          if isPiper
            address = @_getFirstBitcoinAddress mnemonic
            @_sendRequest IP, pubKey, address, mnemonic
          else
            l 'No piper print!'


  _canUsePiper: (cb) ->
    @getIP (IP) =>
      @getPubKey (pubKey) =>
        cb?(IP? and pubKey?)


  _getFirstBitcoinAddress: (mnemonic) ->
    seed = ledger.bitcoin.bip39.generateSeed mnemonic
    bip32RootKey = bitcoin.HDNode.fromSeedHex(seed, bitcoin.networks.bitcoin)
    bip32ExtendedKey = bip32RootKey

    # Derive the key from the path
    path = "m/44'/0'/0'/0"
    pathBits = path.split("/")
    for val, i in pathBits
      bit = pathBits[i]
      index = parseInt(bit)
      if (isNaN index)
        continue
    hardened = bit[bit.length-1] == "'"
    if (hardened)
      bip32ExtendedKey = bip32ExtendedKey.deriveHardened(index)
    else
      bip32ExtendedKey = bip32ExtendedKey.derive(index)
      key = bip32ExtendedKey.derive(index)
      address = key.getAddress().toString()
      address


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

