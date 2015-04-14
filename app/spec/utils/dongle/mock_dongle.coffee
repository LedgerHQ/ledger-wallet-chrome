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

    _btchipQueue.enqueue "confirmSecureScreen", =>
      @_btchip.createPaymentTransaction_async(
        inputs, associatedKeysets, changePath,
        new ByteString(recipientAddress, ASCII),
        amount.toByteString(),
        fees.toByteString(),
        lockTime && new ByteString(Convert.toHexInt(lockTime), HEX),
        sighashType && new ByteString(Convert.toHexInt(sighashType), HEX),
        authorization && new ByteString(authorization, HEX),
        resumeData
      ).then (result) ->
        l result
        switch typeof result
          when 'object'
            result.scriptData = result.scriptData.toString(HEX)
            result.trustedInputs = (trustedInput.toString(HEX) for trustedInput in result.trustedInputs)
            # "03b6baa018cf705f0f58e1089106972f3d5287a98594cac2b1befc4f32c770443a,02439f792dc1cb17263eabe5f3aa4d5c2f6ef1eac866761a93d1786a893fd854b1"
            result.publicKeys = (publicKey.toString(HEX) for publicKey in result.publicKeys)
            result.authorizationPaired = result.authorizationPaired.toString(HEX) if result.authorizationPaired?
            result.authorizationReference = result.authorizationReference.toString(HEX) if result.authorizationReference?
          when 'string'
            result = result.toString(HEX)

        ###
        ###
        tx = new bitcoin.Transaction()

        # Add the input (who is paying) of the form [previous transaction hash, index of the output to use]
        tx.addInput("aa94ab02c182214f090e99a0d57021caffd0f195a81c24602b1028b130b63e31", 0)

        # Add the output (who to pay to) of the form [payee's address, amount in satoshis]
        tx.addOutput(@bitcoinAddress, amount.toSatoshiNumber())

        # Initialize a private key using WIF
        key = bitcoin.ECKey.fromWIF("L1uyy5qTuGrVXrmrsvHWHgVzW9kKdrp27wBC7Vs6nZDTF2BRUVwy")

        # Sign the first input with the new key
        tx.sign(0, key)

        # Print transaction serialized as hex
        console.log(tx.toHex())
        # => 0100000001313eb630b128102b60241ca895f1d0ffca21 ...
        ###
        ###


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