# ledger.app.donglesManager.createDongle('0000', 'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff')

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


  signMessage: (message, {path, pubKey}, callback=undefined) ->
    d = ledger.defer(callback)
    node = @_getNodeFromPath(path)
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


  # @return [Q.Promise]
  isFirmwareUpdateAvailable: (callback=undefined) -> ledger.defer(callback).resolve(true).promise



  ###
  @param [Array<Object>] inputs
  @param [Array] associatedKeysets
  @param changePath
  @param [String] recipientAddress
  @param [Amount] amount
  @param [Amount] fee
  @param [Integer] lockTime
  @param [Integer] sighashType
  @param [String] authorization hex encoded
  @param [Object] resumeData
  @return [Q.Promise] Resolve with resumeData
  ###

  # ledger.wallet.Transaction(ledger.dongle.Dongle(), 6000, 10, 'dedrtftyugyihujik', ['de','de'] )

  createPaymentTransaction: (inputs, associatedKeysets, changePath, recipientAddress, amount, fees, lockTime, sighashType, authorization, resumeData) ->
    if resumeData?
      resumeData = _.clone(resumeData)
      resumeData.scriptData = new ByteString(resumeData.scriptData, HEX)
      resumeData.trustedInputs = (new ByteString(trustedInput, HEX) for trustedInput in resumeData.trustedInputs)
      resumeData.publicKeys = (new ByteString(publicKey, HEX) for publicKey in resumeData.publicKeys)


    # Mock
    txb = new bitcoin.TransactionBuilder()

    rawTxs = for input in @_btInputs
      [splittedTx, outputIndex] = input
      rawTxBuffer = splittedTx.version
      rawTxBuffer = rawTxBuffer.concat(new ByteString(Convert.toHexByte(splittedTx.inputs.length), HEX))
      for input in splittedTx.inputs
        rawTxBuffer = rawTxBuffer.concat(input.prevout).concat(new ByteString(Convert.toHexByte(input.script.length), HEX)).concat(input.script).concat(input.sequence)
      rawTxBuffer = rawTxBuffer.concat(new ByteString(Convert.toHexByte(splittedTx.outputs.length), HEX))
      for output in splittedTx.outputs
        rawTxBuffer = rawTxBuffer.concat(output.amount).concat(new ByteString(Convert.toHexByte(output.script.length), HEX)).concat(output.script)
      rawTxBuffer = rawTxBuffer.concat(splittedTx.locktime)
      [rawTxBuffer, outputIndex]

    values = []
    balance = Bitcoin.BigInteger.valueOf(0)

    for [rawTx, outputIndex] in rawTxs
      tx = bitcoin.Transaction.fromHex(rawTx.toString())
      txb.addInput(tx, outputIndex)
      values.push(tx.outs[outputIndex].value)
    for val, i in values
      balance = balance.add Bitcoin.BigInteger.valueOf(val)

    change = (balance.toString() - @fees) - @amount.toString()

    l balance.toString()
    l @amount
    l @fees

    # Get Hash from base58
    arr = ledger.crypto.Base58.decode(@recipientAddress)
    buffer = JSUCrypt.utils.byteArrayToHexStr(arr)
    x = new ByteString(buffer, HEX)
    pubKeyHash = x.bytes(0, x.length - 4).bytes(1) # remove network 1, remove checksum 4
    l pubKeyHash

    scriptPubKeyStart = Convert.toHexByte(bitcoin.opcodes.OP_DUP) + Convert.toHexByte(bitcoin.opcodes.OP_HASH160) + 14
    scriptPubKeyEnd = Convert.toHexByte(bitcoin.opcodes.OP_EQUALVERIFY) + Convert.toHexByte(bitcoin.opcodes.OP_CHECKSIG)
    scriptPubKey = bitcoin.Script.fromHex(scriptPubKeyStart + pubKeyHash.toString() + scriptPubKeyEnd)

    txb.addOutput(scriptPubKey, @amount.toNumber()) # recipient addr
    txb.addOutput(scriptPubKey, change) # change addr


    node = @_getNodeFromPath(associatedKeysets)
    l node

    #for input, index in tx.ins
      #txb.sign(index, node)
    return result


  splitTransaction: (input) ->
    bitExt = new BitcoinExternal()
    bitExt.splitTransaction(new ByteString(input.raw, HEX))


  _setState: (newState, args...) ->
    [@state, oldState] = [newState, @state]
    @emit "state:#{@state}", @state, args...
    @emit 'state:changed', @state


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


  _getNodeFromPath: (path) ->
    path = path.split('/')
    node = @_masterNode
    for item in path
      [index, hardened] = item.split "'"
      node  = if hardened? then node.deriveHardened parseInt(index) else node = node.derive index
    node