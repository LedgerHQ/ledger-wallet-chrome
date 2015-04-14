States =
# Dongle juste created, not initialized.
  UNDEFINED: undefined
# PIN required.
  LOCKED: 'locked'
# PIN has been verified.
  UNLOCKED: 'unlocked'
# No seed present, dongle must be setup.
  BLANK: 'blank'
# Dongle has been unplugged.
  DISCONNECTED: 'disconnected'
# An error appended, user must unplug/replug dongle.
  ERROR: 'error'

Errors = @ledger.errors


class ledger.dongle.MockDongle extends EventEmitter

  # @property [Array<ledger.wallet.ExtendedPublicKey>]
  _xpubs: []


  constructor: (pin, seed, isInBootloaderMode = no) ->
    super
    @_isInBootloaderMode = isInBootloaderMode
    @state = States.UNDEFINED
    @_setState(States.BLANK)
    @_setup(pin, seed) if pin? and seed?



  isInBootloaderMode: -> @_isInBootloaderMode


  disconnect: () -> @_setState(States.DISCONNECTED)

  # Return asynchronosly state. Wait until a state is set.
  # @param [Function] callback Optional argument
  # @return [Q.Promise]
  getState: (callback=undefined) -> ledger.defer(callback).resolve(@state).promise


  _setState: (newState, args...) ->
    [@state, oldState] = [newState, @state]
    @emit "state:#{@state}", @state, args...
    @emit 'state:changed', @state


  # @param [String] pin ASCII encoded
  # @param [Function] callback Optional argument
  # @return [Q.Promise]
  unlockWithPinCode: (pin, callback=undefined) ->
    Errors.throw(Errors.DongleAlreadyUnlock) if @state isnt States.LOCKED
    d = ledger.defer(callback)
    if pin is @_pin
      @_setState(States.UNLOCKED)
      d.resolve()
    else
      d.reject()
    d.promise


  setup: (pin, restoreSeed, callback=undefined) =>
    d = ledger.defer(callback)
    Errors.throw(Errors.DongleNotBlank) if @state isnt States.BLANK
    [restoreSeed, callback] = [callback, restoreSeed] if ! callback && typeof restoreSeed == 'function'
    Throw new Error('Setup need a seed') if not restoreSeed?
    @_pin = pin
    @_masterNode = bitcoin.HDNode.fromSeedHex(restoreSeed)
    # Validate seed
    if restoreSeed?
      bytesSeed = new ByteString(restoreSeed, HEX)
      if bytesSeed.length != 64
        e('Invalid seed :', restoreSeed)
    d.resolve()
    return d.promise


  _setup: (pin, restoreSeed, callback=undefined) =>
    d = ledger.defer(callback)
    Errors.throw(Errors.DongleNotBlank) if @state isnt States.BLANK
    [restoreSeed, callback] = [callback, restoreSeed] if ! callback && typeof restoreSeed == 'function'
    Throw new Error('Setup need a seed') if not restoreSeed?

    @_pin = pin
    @_masterNode = bitcoin.HDNode.fromSeedHex(restoreSeed)
    # Validate seed
    if restoreSeed?
      bytesSeed = new ByteString(restoreSeed, HEX)
      if bytesSeed.length != 64
        e('Invalid seed :', restoreSeed)

    @_setState(States.DISCONNECTED)
    ledger.app.donglesManager.powerCycle(1000)
    @_setState(States.LOCKED)
    d.resolve()
    return d.promise


  # @param [String] path
  # @param [Function] callback Optional argument
  # @return [Q.Promise]
  getPublicAddress: (path, callback=undefined) ->
    d = ledger.defer(callback)
    Errors.throw(Errors.DongleLocked, 'Cannot get a public while the key is not unlocked') if @state isnt States.UNLOCKED && @state isnt States.UNDEFINED
    res = @getPublicAddressSync(path)
    ledger.wallet.HDWallet.instance?.cache?.set [[path, res]]
    _.defer => d.resolve(res)
    return d.promise


  getPublicAddressSync: (path) ->
    node = @_getNodeFromPath(path)
    bitcoinAddress: new ByteString node.getAddress().toString(), ASCII
    chainCode: new ByteString (Convert.toHexByte(n) for n in node.chainCode).join(''), HEX
    publicKey: new ByteString do (->
        node.pubKey.compressed = false
        node.pubKey.toHex()
      )
    , HEX


  _getNodeFromPath: (path) ->
    path = path.split('/')
    node = @_masterNode
    for item in path
      [index, hardened] = item.split "'"
      node  = if hardened? then node.deriveHardened parseInt(index) else node = node.derive index
    node


  signMessage: (message, {path, pubKey}, callback=undefined) ->
    d = ledger.defer(callback)
    node = @_getNodeFromPath(path)
    l node
    d.resolve bitcoin.Message.sign(node.privKey, message).toString('base64')
    d.promise


  getBitIdAddress: (subpath=undefined, callback=undefined) ->
    Errors.throw(Errors.DongleLocked) if @state isnt States.UNLOCKED
    [subpath, callback] = [callback, subpath] if ! callback && typeof subpath == 'function'
    path = ledger.dongle.BitIdRootPath
    path += "/#{subpath}" if subpath?
    @getPublicAddress(path, callback)


  # @param [String] path
  # @param [Function] callback Optional argument
  # @return [Q.Promise] Resolve if pairing is successful.
  getExtendedPublicKey: (path, callback=undefined) ->
    Errors.throw(Errors.DongleLocked) if @state != States.UNLOCKED
    d = ledger.defer(callback)
    return d.resolve(@_xpubs[path]).promise if @_xpubs[path]?
    xpub = new ledger.wallet.ExtendedPublicKey(@, path)
    xpub.initialize () =>
      @_xpubs[path] = xpub
      d.resolve(xpub)
    d.promise


  isCertified: (callback=undefined) =>
    d = ledger.defer(callback)
    d.resolve(@)
    d.promise


  isBetaCertified: (callback=undefined) =>
    d = ledger.defer(callback)
    d.resolve(@)
    d.promise


  _convertMessageSignature: (pubKey, message, signature) ->
    bitcoin = new BitcoinExternal()
    hash = bitcoin.getSignedMessageHash(message)
    pubKey = bitcoin.compressPublicKey(pubKey)
    for i in [0...4]
      recoveredKey = bitcoin.recoverPublicKey(signature, hash, i)
      l recoveredKey
      recoveredKey = bitcoin.compressPublicKey(recoveredKey)
      l recoveredKey
      if recoveredKey.equals(pubKey)
        splitSignature = bitcoin.splitAsn1Signature(signature)
        sig = new ByteString(Convert.toHexByte(i + 27 + 4), HEX).concat(splitSignature[0]).concat(splitSignature[1])
        break
    throw "Recovery failed" if ! sig?
    return @_convertBase64(sig)

  _convertBase64: (data) ->
    codes = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    output = ""
    leven = 3 * (Math.floor(data.length / 3))
    offset = 0
    for i in [0...leven] when i % 3 == 0
      output += codes.charAt((data.byteAt(offset) >> 2) & 0x3f)
      output += codes.charAt((((data.byteAt(offset) & 3) << 4) + (data.byteAt(offset + 1) >> 4)) & 0x3f)
      output += codes.charAt((((data.byteAt(offset + 1) & 0x0f) << 2) + (data.byteAt(offset + 2) >> 6)) & 0x3f)
      output += codes.charAt(data.byteAt(offset + 2) & 0x3f)
      offset += 3
    if i < data.length
      a = data.byteAt(offset)
      b = if (i + 1) < data.length then data.byteAt(offset + 1) else 0
      output += codes.charAt((a >> 2) & 0x3f)
      output += codes.charAt((((a & 3) << 4) + (b >> 4)) & 0x3f)
      output += if (i + 1) < data.length then codes.charAt((((b & 0x0f) << 2)) & 0x3f) else '='
      output += '='
    return output
