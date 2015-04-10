
ledger.wallet ?= {}

_store = null
store = -> _store ||= new ledger.storage.ChromeStore("wallet_setup_consistency_checker")

class MemoryWallet

  constructor: (seed) ->
    @_masterNode = bitcoin.HDNode.fromSeedHex(seed.toString())

  getPublicAddress: (path, callback) ->
    _.defer => callback?(@getPublicAddressSync(path))

  getPublicAddressSync: (path) ->
    path = path.split('/')
    node = @_masterNode
    for item in path
      [index, hardened] = item.split "'"
      node  = if hardened? then node.deriveHardened parseInt(index) else node = node.derive index
    bitcoinAddress: new ByteString node.getAddress().toString(), ASCII
    chainCode: new ByteString (Convert.toHexByte(n) for n in node.chainCode).join(''), HEX
    publicKey: new ByteString do (->
      node.pubKey.compressed = false
      node.pubKey.toHex()
    )
    , HEX

class ledger.wallet.WalletSetupConsistencyChecker

  constructor: () ->

  isWalletSetupConsistent: (wallet, callback) ->
    store().get "__wscc_", (items) =>
      {__wscc_} = items
      return callback?(true) unless __wscc_?
      @_createConsistencyTest wallet, (test) =>
        isConsistent = _.isEqual(__wscc_, test)
        store().remove(["__wscc_"]) if isConsistent
        callback?(isConsistent)

  setConsistencyTest: (walletSeed) ->
    wallet = new MemoryWallet(walletSeed)
    @_createConsistencyTest wallet, (test) =>
      store().set __wscc_: test

  _createConsistencyTest: (wallet, callback) ->
    xpub = new ledger.wallet.ExtendedPublicKey(wallet, "44'/0'/0'", no)
    xpub.initialize ->
      wallet.getPublicAddress "0'/0/0xb11e", (bitIdAddress) ->
        wallet.getPublicAddress "0x50DA'/0xBED'/0xC0FFEE'", (storageAddress) ->
          callback(xpub: xpub.toString(), bitid: bitIdAddress.bitcoinAddress.toString(ASCII), storage: storageAddress.bitcoinAddress.toString(ASCII))