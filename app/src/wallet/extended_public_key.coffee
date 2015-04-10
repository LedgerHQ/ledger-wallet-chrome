
@ledger ?= {}
@ledger.wallet ?= {}

GlobalContext = @

class ledger.wallet.ExtendedPublicKey

  constructor: (wallet, derivationPath, enableCache = yes) ->
    @_enableCache = enableCache
    @_derivationPath = derivationPath
    if derivationPath[derivationPath.length - 1] isnt '/'
      @_derivationPath += '/'
    @_wallet = wallet

  initialize: (callback) ->
    derivationPath = @_derivationPath.substring(0, @_derivationPath.length - 1)
    path = derivationPath.split '/'
    bitcoin = new BitcoinExternal()
    finalize = (fingerprint) =>
      @_wallet.getPublicAddress derivationPath, (nodeData, error) =>
        return callback?(null, error) if error?
        publicKey = bitcoin.compressPublicKey nodeData.publicKey
        depth = path.length
        lastChild = path[path.length - 1].split('\'')
        childnum = parseInt(lastChild[0]) if lastChild.length is 1
        childnum = (0x80000000 | parseInt(lastChild)) >>> 0
        @_xpub = @_createXPUB depth, fingerprint, childnum, nodeData.chainCode, publicKey
        @_xpub58 = @_encodeBase58Check @_xpub
        @_hdnode = GlobalContext.bitcoin.HDNode.fromBase58 @_xpub58
        callback?(@)

    if path.length > 1
      prevPath = path.slice(0, -1).join '/'
      @_wallet.getPublicAddress prevPath, (nodeData, error) =>
        return callback?(null, error) if error?
        publicKey = bitcoin.compressPublicKey nodeData.publicKey
        ripemd160 = new JSUCrypt.hash.RIPEMD160()
        sha256 = new JSUCrypt.hash.SHA256();
        result = sha256.finalize(publicKey.toString(HEX));
        result = new ByteString(JSUCrypt.utils.byteArrayToHexStr(result), HEX)
        result = ripemd160.finalize(result.toString(HEX))
        fingerprint = ((result[0] << 24) | (result[1] << 16) | (result[2] << 8) | result[3]) >>> 0
        finalize fingerprint
    else
      finalize 0

  _createXPUB: (depth, fingerprint, childnum, chainCode, publicKey, testnet = no) ->
    magic = if testnet then  "043587CF" else "0488B21E"
    xpub = new ByteString magic, HEX
    xpub = xpub.concat new ByteString(_.str.lpad(depth.toString(16), 2, '0'), HEX)
    xpub = xpub.concat new ByteString(_.str.lpad(fingerprint.toString(16), 8, '0'), HEX)
    xpub = xpub.concat new ByteString(_.str.lpad(childnum.toString(16), 8, '0'), HEX)
    xpub = xpub.concat new ByteString(chainCode.toString(HEX), HEX)
    xpub = xpub.concat new ByteString(publicKey.toString(HEX), HEX)
    xpub

  _encodeBase58Check: (vchIn) ->
    sha256 = new JSUCrypt.hash.SHA256();
    hash = sha256.finalize(vchIn.toString(HEX))
    hash = sha256.finalize(JSUCrypt.utils.byteArrayToHexStr(hash))
    hash = new ByteString(JSUCrypt.utils.byteArrayToHexStr(hash), HEX).bytes(0, 4)
    hash = vchIn.concat(hash)
    @_b58Encode hash

  __b58chars: '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz'

  _b58Encode: (v) ->
    long_value = ledger.wallet.Value.from 0
    value256 = ledger.wallet.Value.from 256
    for i in [(v.length - 1)..0]
      long_value = long_value.add value256.pow(v.length - i - 1).multiply(v.byteAt(i))

    result = ''
    while long_value.gte @__b58chars.length
      div = long_value.divide(@__b58chars.length)
      mod = long_value.mod(@__b58chars.length)
      result = @__b58chars[mod.toNumber()] + result
      long_value = div
    result = @__b58chars[long_value.toNumber()] + result
    result

  getPublicAddress: (path) ->
    throw 'Extended public key must initialized before it can perform any derivation' unless @_xpub?
    throw 'Path should begin by the index of derivation' if isNaN(parseInt(path[0]))
    partialPath = path

    address = @_getPublicAddressFromCache(partialPath)
    return address if address?

    path = path.split '/'
    hdnode = @_hdnode
    for node in path
      [index, hardened] = node.split "'"
      if hardened?
        hdnode = hdnode.deriveHardened parseInt(index)
      else
        hdnode = hdnode.derive parseInt(index)
    address = hdnode.getAddress().toString()
    @_insertPublicAddressInCache partialPath, address
    address

  _insertPublicAddressInCache: (partialPath, publicAddress) ->
    return unless @_enableCache
    completePath = @_derivationPath + partialPath
    ledger.wallet?.HDWallet?.instance?.cache?.set [[completePath, publicAddress]]

  _getPublicAddressFromCache: (partialPath) ->
    return unless @_enableCache
    completePath = @_derivationPath + partialPath
    ledger.wallet?.HDWallet?.instance?.cache?.get completePath

  toString: -> @_xpub58