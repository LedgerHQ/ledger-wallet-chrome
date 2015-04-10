
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
    toto =
      bitcoinAddress: new ByteString node.getAddress().toString(), ASCII
      chainCode: new ByteString (Convert.toHexByte(n) for n in node.chainCode).join(''), HEX
      publicKey: new ByteString "04#{node.pubKey.Q.x.toHex()}#{node.pubKey.Q.y.toHex()}", HEX
    l "Derivatinh #{path}", toto
    bitcoinAddress: new ByteString node.getAddress().toString(), ASCII
    chainCode: new ByteString (Convert.toHexByte(n) for n in node.chainCode).join(''), HEX
    publicKey: new ByteString "04#{node.pubKey.Q.x.toHex()}#{node.pubKey.Q.y.toHex()}", HEX

class ledger.wallet.WalletSetupConsistencyChecker

  constructor: () ->

  isWalletSetupConsistent: (callback) ->
    store().get "__wscc_", (items) =>
      l items

  setConsistencyTest: (walletSeed) ->
    wallet = new MemoryWallet(walletSeed)
    xpub = new ledger.wallet.ExtendedPublicKey(wallet, "44'/0'/0'", no)
    xpub.initialize ->
      bitIdAddress = wallet.getPublicAddressSync("0'/0/0xb11e")
      storageAddress = wallet.getPublicAddressSync("0x50DA'/0xBED'/0xC0FFEE'")
      store().set __wscc_: {xpub: xpub.toString(), bitid: bitIdAddress.bitcoinAddress.toString(ASCII), storage: storageAddress.bitcoinAddress.toString(ASCII)}
