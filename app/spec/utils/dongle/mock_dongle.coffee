
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

  _xpubs: []
  _remainingPinAttempt: 2

  # M2FA
  _m2fa:
    pubKey: "04"+"78c0837ded209265ea8131283585f71c5bddf7ffafe04ccddb8fe10b3edc7833"+"d6dee70c3b9040e1a1a01c5cc04fcbf9b4de612e688d09245ef5f9135413cc1d"
    privKey: "80"+"dbd39adafe3a007706e61a17e0c56849146cfe95849afef7ede15a43a1984491"+"7e960af3"
    sessionKey: ''
    pairingKeyHex: ''
    nonceHex: ''
    challengeIndexes: ''
    challengeResponses: ''
    keycard: ''

  constructor: (pin, seed, pairingKeyHex = undefined, isInBootloaderMode = no) ->
    super
    @_m2fa = _.clone(@_m2fa)
    @_m2fa.pairingKeyHex = pairingKeyHex
    @_isInBootloaderMode = isInBootloaderMode
    @state = States.UNDEFINED
    @_setState(States.BLANK)
    @_setup(pin, seed, yes) if pin? and seed?


  isInBootloaderMode: -> @_isInBootloaderMode


  disconnect: () ->
    @emit 'disconnected', @
    @_setState(States.DISCONNECTED)


  connect: () ->
    @emit 'connected', @
    @_setState(States.LOCKED)


  # Return asynchronosly state. Wait until a state is set.
  # @param [Function] callback Optional argument
  # @return [Q.Promise]
  getState: (callback=undefined) -> ledger.defer(callback).resolve(@state).promise


  # @return [Integer] Firmware version, 0x20010000010f for example.
  getIntFirmwareVersion: ->
    parseInt(0x0001040d0146.toString(HEX), 16)


  ###
    Gets the raw version {ByteString} of the dongle.

    @param [Boolean] isInBootLoaderMode Must be true if the current dongle is in bootloader mode.
    @param [Boolean] forceBl Force the call in BootLoader mode
    @param [Function] callback Called once the version is retrieved. The callback must be prototyped like size `(version, error) ->`
    @return [Q.Promise]
  ###
  getRawFirmwareVersion: (isInBootLoaderMode, forceBl=no, callback=undefined) ->
    d = ledger.defer(callback)
    try
      d.resolve ['00000020', '00010001']
    catch
      d.rejectWithError(ledger.errors.UnknowError, error)
      console.error("Fail to getRawFirmwareVersion :", error)
    d.promise


  # @param [String] pin ASCII encoded
  # @param [Function] callback Optional argument
  # @return [Q.Promise]
  unlockWithPinCode: (pin, callback=undefined) ->
    Errors.throw(Errors.DongleAlreadyUnlock) if @state isnt States.LOCKED
    d = ledger.defer(callback)
    if pin is @_pin
      @_setState(States.UNLOCKED)
      @_remainingPinAttempt = 3
      d.resolve()
    else
      console.error("Fail to unlockWithPinCode 1 :", '63c' + @_remainingPinAttempt)
      error = @_handleErrorCode('63c' + @_remainingPinAttempt)
      @_remainingPinAttempt -= 1
      d.reject(error)
    d.promise


  lock: () ->
    if @state isnt ledger.dongle.States.BLANK and @state?
      @_setState(States.LOCKED)


  # @return [Q.Promise] resolve with a Number, reject with a ledger Error.
  getRemainingPinAttempt: (callback=undefined) ->
    d = ledger.defer(callback)
    if @_remainingPinAttempt < 0
        d.resolve(@_remainingPinAttempt)
    else
        d.reject(@_handleErrorCode('6985'))
    d.promise


  setup: (pin, restoreSeed, callback=undefined) ->
    @_setup(pin, restoreSeed, no, callback)


  # @param [String] path
  # @param [Function] callback Optional argument
  # @return [Q.Promise]
  getPublicAddress: (path, callback=undefined) ->
    d = ledger.defer(callback)
    Errors.throw(Errors.DongleLocked, 'Cannot get a public while the key is not unlocked') if @state isnt States.UNLOCKED && @state isnt States.UNDEFINED
    res = @getPublicAddressSync(path)
    ledger.wallet.Wallet.instance?.cache?.set [[path, res.bitcoinAddress.value]]
    _.defer -> d.resolve(res)
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


  isCertified: (callback=undefined) ->
    d = ledger.defer(callback)
    d.resolve(@)
    d.promise


  isBetaCertified: (callback=undefined) ->
    d = ledger.defer(callback)
    d.resolve(@)
    d.promise


  # @return [Q.Promise]
  isFirmwareUpdateAvailable: (callback=undefined) -> ledger.defer(callback).resolve(false).promise


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
  createPaymentTransaction: (inputs, associatedKeysets, changePath, recipientAddress, amount, fees, lockTime, sighashType, authorization, resumeData, network) ->
    d = ledger.defer()
    result = {}

    if _.isEmpty resumeData
      txb = new bitcoin.TransactionBuilder()
      # Create rawTxs from inputs
      rawTxs = for input in inputs
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

      # Add Input
      for [rawTx, outputIndex] in rawTxs
        tx = bitcoin.Transaction.fromHex(rawTx.toString())
        txb.addInput(tx, outputIndex)
        values.push(tx.outs[outputIndex].value)
      # Create balance
      for val, i in values
        balance = balance.add Bitcoin.BigInteger.valueOf(val)

      # Create change
      change = (balance.toString() - fees.toSatoshiNumber()) - amount.toSatoshiNumber()

      # Create scriptPubKey
      scriptPubKeyStart = Convert.toHexByte(bitcoin.opcodes.OP_DUP) + Convert.toHexByte(bitcoin.opcodes.OP_HASH160) + 14
      scriptPubKeyEnd = Convert.toHexByte(bitcoin.opcodes.OP_EQUALVERIFY) + Convert.toHexByte(bitcoin.opcodes.OP_CHECKSIG)

      # recipient addr
      scriptPubKey = bitcoin.Script.fromHex(scriptPubKeyStart + @_getPubKeyHashFromBase58(recipientAddress).toString() + scriptPubKeyEnd)
      txb.addOutput(scriptPubKey, amount.toSatoshiNumber())
      # change addr
      scriptPubKey = bitcoin.Script.fromHex(scriptPubKeyStart + @_getPubKeyHashFromBase58(@_getNodeFromPath(changePath).getAddress().toString()).toString() + scriptPubKeyEnd)
      if change isnt 0
        txb.addOutput(scriptPubKey, change)

      # Signature
      for path, index in associatedKeysets
        txb.sign(index, @_getNodeFromPath(associatedKeysets[index]).privKey)

      # Keycard
      keycard = ledger.keycard.generateKeycardFromSeed('dfaeee53c3d280707bbe27720d522ac1')
      charsQuestion = []
      indexes = [] # charQuestion indexes of recipient address
      charsResponse = []
      for i in [0..3]
        randomNum = _.random recipientAddress.length - 1
        charsQuestion.push recipientAddress.charAt randomNum
        charsResponse.push keycard[charsQuestion[i]]
        indexes.push Convert.toHexByte randomNum

      result.authorizationReference = indexes.join('')
      result.publicKeys = []
      result.publicKeys.push recipientAddress
      result.txb = txb
      result.charsResponse = "0" + charsResponse.join('0')

      # M2fa
      if @_m2fa.pairingKeyHex?
        amount = '0000000000000000' + amount._value.toRadix(16)
        amount = amount.substr(amount.length - 16, 16)
        fees = '0000000000000000' + fees._value.toRadix(16)
        fees = fees.substr(fees.length - 16, 16)
        change = '0000000000000000' + new BigInteger(change.toString()).toRadix(16)
        change = change.substr(change.length - 16, 16)
        sizeAddress = Convert.toHexByte recipientAddress.length
        pin = new ByteString(charsResponse.join(''), ASCII).toString(HEX)
        m2faData = pin + amount + fees + change + sizeAddress + (new ByteString(recipientAddress, ASCII).toString(HEX))
        padding = m2faData.length % 8
        m2faData = _.str.rpad m2faData, m2faData.length + (8 - padding), '0'
        # Encrypt
        cipher = new JSUCrypt.cipher.DES(JSUCrypt.padder.None , JSUCrypt.cipher.MODE_CBC)
        key = new JSUCrypt.key.DESKey(@_m2fa.pairingKeyHex)
        cipher.init(key, JSUCrypt.cipher.MODE_ENCRYPT)
        m2faData = cipher.update(m2faData)
        m2faDataHex = (Convert.toHexByte(v) for v in m2faData).join('')
        # Set authorizations
        result.authorizationRequired = 3
        result.authorizationPaired = m2faDataHex
        result.indexesKeyCard = '04' + indexes.join('') + m2faDataHex
      else
        result.authorizationRequired = 2
        result.authorizationPaired = undefined
        result.indexesKeyCard = indexes.join('')

      l 'result', result
      l 'm2fa', @_m2fa
      result
    else
      l 'resumeData', resumeData
      # Check keycard and m2fa validity
      m2faResponse = new ByteString((v.charAt(1) for v in resumeData.charsResponse.match(/.{2}/g)).join(''), ASCII).toString(HEX)
      if resumeData.charsResponse isnt authorization and m2faResponse isnt authorization
        _.delay (-> d.rejectWithError(Errors.WrongPinCode)), 1000
      # Build raw tx
      try
        result = resumeData.txb.build().toHex()
      catch
        _.delay (-> d.rejectWithError(Errors.SignatureError)), 1000

    _.delay (-> d.resolve(result)), 1000 # Dirty delay fix, odd but necessary
    d.promise


  splitTransaction: (input) ->
    bitExt = new BitcoinExternal()
    bitExt.splitTransaction(new ByteString(input.raw, HEX))


  # @param [String] pubKey public key, hex encoded. # Remote screen uncompressed public key - 65 length
  # @param [Function] callback Optional argument
  # @return [Q.Promise] Resolve with a 32 bytes length pairing blob hex encoded. # Pairing blob : 8 bytes random nonce and (4 bytes keycard challenge + 16 bytes pairing key) encrypted by the session key # Challenge
  initiateSecureScreen: (pubKey, callback=undefined) ->
    d = ledger.defer(callback)
    if @state != States.UNLOCKED
      d.rejectWithError(Errors.DongleLocked)
    else if ! pubKey.match(/^[0-9A-Fa-f]{130}$/)?
      d.rejectWithError(Errors.InvalidArgument, "Invalid pubKey : #{pubKey}")
    else
      ###
        The remote screen public key is sent to the dongle, which generates
        a cleartext random 8 bytes nonce,
        a 4 bytes challenge on the printed keycard
        and a random 16 bytes 3DES-2 pairing key, concatenated and encrypted using 3DES CBC and the generated session key
      ###
      # ECDH key exchange
      ecdhdomain = JSUCrypt.ECFp.getEcDomainByName("secp256k1")
      ecdhprivkey = new JSUCrypt.key.EcFpPrivateKey(256, ecdhdomain, @_m2fa.privKey.match(/^(\w{2})(\w{64})(01)?(\w{8})$/)[2])
      ecdh = new JSUCrypt.keyagreement.ECDH_SVDP(ecdhprivkey)
      aKey = pubKey.match(/^(\w{2})(\w{64})(\w{64})$/)
      secret = ecdh.generate(new JSUCrypt.ECFp.AffinePoint(aKey[2], aKey[3], ecdhdomain.curve)) # 32 bytes secret is obtained
      # Split into two 16 bytes components S1 and S2. S1 and S2 are XORed to produce a 16 bytes 3DES-2 session key
      @_m2fa.sessionKey = (Convert.toHexByte(secret[i] ^ secret[16+i]) for i in [0...16]).join('')
      # Challenge (keycard indexes) - 4 bytes
      @_m2fa.keycard = ledger.keycard.generateKeycardFromSeed('dfaeee53c3d280707bbe27720d522ac1')
      @_m2fa.challengeIndexes = ''
      @_m2fa.challengeResponses = ''
      for i in [0..3]
        num = _.random(ledger.crypto.Base58.concatAlphabet().length - 1)
        @_m2fa.challengeIndexes += Convert.toHexByte(ledger.crypto.Base58.concatAlphabet().charCodeAt(num) - 0x30)
        @_m2fa.challengeResponses += '0' + @_m2fa.keycard[ledger.crypto.Base58.concatAlphabet().charAt(num)]
      # Crypted challenge - challenheHex + PairingKeyHex - 24 bytes
      blob = @_m2fa.challengeIndexes + @_m2fa.pairingKeyHex + "00000000"
      cipher = new JSUCrypt.cipher.DES(JSUCrypt.padder.None, JSUCrypt.cipher.MODE_CBC)
      key = new JSUCrypt.key.DESKey(@_m2fa.sessionKey)
      cipher.init(key, JSUCrypt.cipher.MODE_ENCRYPT)
      cryptedBlob = cipher.update(blob)
      cryptedBlobHex = (Convert.toHexByte(v) for v in cryptedBlob).join('')
      # 8 bytes Nonce
      nonce = crypto.getRandomValues new Uint8Array(8)
      @_m2fa.nonceHex = (Convert.toHexByte(v) for v in nonce).join('')
      # concat Nonce + (challenge + pairingKey)
      res = @_m2fa.nonceHex + cryptedBlobHex
      d.resolve(res)
    d.promise


  # @param [String] resp challenge response, hex encoded.  #Encrypted nonce and challenge response + padding - 16 length
  # @param [Function] callback Optional argument
  # @return [Q.Promise] Resolve if pairing is successful.
  confirmSecureScreen: (challengeResp, callback=undefined) ->
    d = ledger.defer(callback)
    if @state != States.UNLOCKED
      d.rejectWithError(Errors.DongleLocked)
    else if ! challengeResp.match(/^[0-9A-Fa-f]{32}$/)?
      d.rejectWithError(Errors.InvalidArgument, "Invalid challenge resp : #{challengeResp}")
    else
      # Decipher
      cipher = new JSUCrypt.cipher.DES(JSUCrypt.padder.None, JSUCrypt.cipher.MODE_CBC)
      key = new JSUCrypt.key.DESKey(@_m2fa.sessionKey)
      cipher.init(key, JSUCrypt.cipher.MODE_DECRYPT)
      challengeRespDecipher = cipher.update(challengeResp)
      challengeRespDecipher = (Convert.toHexByte(v) for v in challengeRespDecipher).join('')
      #l 'challengeRespDecipher', challengeRespDecipher
      # Verify Challenge
      [nonce, challenge, padding] = [challengeRespDecipher[0...16], challengeRespDecipher[16...24], challengeRespDecipher[24..-1]]
      #l [nonce, challenge, padding]
      if nonce is @_m2fa.nonceHex and challenge is @_m2fa.challengeResponses
        @_clearPairingInfo()
        d.resolve()
      else
        @_clearPairingInfo(yes)
        d.reject('Pairing fail -  Invalid status 1 - 6a80')
    d.promise


  getStringFirmwareVersion: ->
    '1.0.1'


  _generatePairingKeyHex: ->
    pairingKey = crypto.getRandomValues new Uint8Array(16)
    @_m2fa.pairingKeyHex = (Convert.toHexByte(v) for v in pairingKey).join('')


  _clearPairingInfo: (isErr) ->
    if isErr
      @_m2fa = _.omit(@_m2fa, ['challengeIndexes', 'sessionKey', 'nonceHex', 'challengeIndexes', 'challengeResponses', 'keycard', 'pairingKeyHex'])
    else
      @_m2fa = _.omit(@_m2fa, ['challengeIndexes', 'sessionKey', 'nonceHex', 'challengeIndexes', 'challengeResponses', 'keycard'])


  # Get PubKeyHash from base58
  _getPubKeyHashFromBase58: (addr) ->
    arr = ledger.crypto.Base58.decode(addr)
    buffer = JSUCrypt.utils.byteArrayToHexStr(arr)
    x = new ByteString(buffer, HEX)
    pubKeyHash = x.bytes(0, x.length - 4).bytes(1) # remove network 1 byte at the beginning, remove checksum 4 bytes at the end
    pubKeyHash


  _setState: (newState, args...) ->
    [@state, oldState] = [newState, @state]
    @emit "state:#{@state}", @state, args...
    @emit 'state:changed', @state


  _setup: (pin, restoreSeed, isPowerCycle, callback=undefined) ->
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
    if isPowerCycle then @_setState States.LOCKED else _.defer => @_setState States.DISCONNECTED
    d.resolve()
    return d.promise


  _getNodeFromPath: (path) ->
    path = path.split('/')
    node = @_masterNode
    for item in path
      [index, hardened] = item.split "'"
      node  = if hardened? then node.deriveHardened parseInt(index) else node = node.derive index
    node


  # Set appropriate state, and return corresponding Error
  # @param [String] errorCode
  # @return [Error]
  _handleErrorCode: (errorCode) ->
    if errorCode.match("6982") # Pin required
      @_setState(States.LOCKED)
      error = Errors.new(Errors.DongleLocked, errorCode)
    else if errorCode.match("6985") # Error ?
      @_setState(States.BLANK)
      error = Errors.new(Errors.BlankDongle, errorCode)
    else if errorCode.match("6faa")
      @_setState(States.ERROR)
      error = Errors.new(Errors.UnknowError, errorCode)
    else if errorCode.match(/63c\d/)
      error = Errors.new(Errors.WrongPinCode, errorCode)
      error.retryCount = parseInt(errorCode.substr(-1))
      if error.retryCount == 0
        @_setState(States.BLANK)
        error.code = Errors.DongleLocked
      else
        @_setState(States.ERROR)
    else
      @_setState(States.UnknowError)
      error = Errors.new(Errors.UnknowError, errorCode)
    l 'ERROR', error
    return error