
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

Firmware =
  V1_4_11: 0x0001040b0146
  V1_4_12: 0x0001040c0146
  V1_4_13: 0x0001040d0146
  V1_0_0B: 0x20010000010f

# Ledger OS pubKey, used for pairing.
Attestation =
  String: "04c370d4013107a98dfef01d6db5bb3419deb9299535f0be47f05939a78b314a3c29b51fcaa9b3d46fa382c995456af50cd57fb017c0ce05e4a31864a79b8fbfd6"

Attestation.Bytes = parseInt(hex, 16) for hex in Attestation.String.match(/\w\w/g)

# This path do not need a verified PIN to sign messages.
BitIdRootPath = "0'/0/0xb11e"

Errors = @ledger.errors

# Populate dongle namespace.
@ledger.dongle ?= {}
_.extend @ledger.dongle,
  States: States
  Firmware: Firmware
  Attestation: Attestation
  BitIdRootPath: BitIdRootPath

###
Signals :
  @emit connected
  @emit state:changed(States)
  @emit state:locked
  @emit state:unlocked
  @emit state:blank
  @emit state:disconnected
  @emit state:error(args...)
###
class @ledger.dongle.Dongle extends EventEmitter

  # @property
  device_id: undefined
  # @property [String]
  state: States.UNDEFINED
  # @property [Integer]
  firmwareVersion: undefined
  # @property [Integer]
  operationMode: undefined

  # @property [BtChip]
  _btchip: undefined
  # @property [Array<ledger.wallet.ExtendedPublicKey>]
  _xpubs = []

  # @private @property [String] pin used to unlock dongle.
  _pin = undefined

  constructor: (@device_id, card) ->
    super
    @_btchip = new BTChip(card)
    @_recoverFirmwareVersion().then( =>
      return @_recoverOperationMode().q()
    ).then( =>
      # Set dongle state on failure.
      return @getPublicAddress("0'/0/0").q()
    ).then( =>
      # @todo Se connecter directement à la carte sans redemander le PIN
      console.warn("Dongle is already unlock ! Case not handle => Pin Code Required.")
      @_setState(States.LOCKED)
    ).done()

  # Called when 
  disconnect: () -> @_setState(States.DISCONNECTED)

  # @return [String] Firmware version, 1.0.0 for example.
  getStringFirmwareVersion: -> @firmwareVersion.byteAt(1) + "." + @firmwareVersion.byteAt(2) + "." + @firmwareVersion.byteAt(3)
  
  # @return [Integer] Firmware version, 0x20010000010f for example.
  getIntFirmwareVersion: -> @firmwareVersion

  ###
    Gets the raw version {ByteString} of the dongle.

    @param [Boolean] isInBootLoaderMode Must be true if the current dongle is in bootloader mode.
    @param [Boolean] forceBl Force the call in BootLoader mode
    @param [Function] callback Called once the version is retrieved. The callback must be prototyped like size `(version, error) ->`
    @return [CompletionClosure]
  ###
  getRawFirmwareVersion: (isInBootLoaderMode, forceBl=no, callback=undefined) ->
    completion = new CompletionClosure(callback)
    apdu = new ByteString((if !isInBootLoaderMode and !forceBl then "E0C4000000" else "F001000000"), HEX)
    @_sendApdu(apdu).then (result) =>
      sw = @_btchip.card.SW
      if !isInBootLoaderMode and !forceBl
        if sw is 0x9000
          completion.success([result.byteAt(1), (result.byteAt(2) << 16) + (result.byteAt(3) << 8) + result.byteAt(4)])
        else
          # Not initialized now - Retry
          @getRawFirmwareVersion(isInBootLoaderMode, yes).thenForward(completion)
      else
        if sw is 0x9000
          completion.success([0, (result.byteAt(5) << 16) + (result.byteAt(6) << 8) + result.byteAt(7)])
        else if !isInBootLoaderMode and (sw is 0x6d00 or sw is 0x6e00)
          #  Unexpected - let's say it's 1.4.3
          completion.success([0, (1 << 16) + (4 << 8) + (3)])
        else
          completion.failure(new ledger.StandardError(ledger.errors.UnknowError, "Failed to get version"))
    .fail (error) ->
      completion.failure(new ledger.StandardError(ledger.errors.UnknowError, error))
    .done()
    completion.readonly()

  # @return [ledger.fup.FirmwareUpdater]
  getFirmwareUpdater: () -> ledger.fup.FirmwareUpdater.instance

  # @return [Boolean]
  isFirmwareUpdateAvailable: () -> @getFirmwareUpdater().isFirmwareUpdateAvailable(this)

  # Verify that dongle firmware is "official".
  # @param [Function] callback Optional argument
  # @return [CompletionClosure]
  isCertified: (callback=undefined) ->
    completion = new CompletionClosure(callback)
    randomValues = new Uint32Array(2)
    crypto.getRandomValues(randomValues)
    random = _.str.lpad(randomValues[0].toString(16), 8, '0') + _.str.lpad(randomValues[1].toString(16), 8, '0')
    # 24.2. GET DEVICE ATTESTATION
    @_sendApdu(new ByteString("E0"+"C2"+"00"+"00"+"08"+random, HEX), [0x9000])
    .then (result) =>
      attestation = result.toString(HEX)
      dataToSign = attestation.substring(16,32) + random
      dataSig = attestation.substring(32)
      dataSigBytes = (parseInt(n,16) for n in dataSig.match(/\w\w/g))

      sha = new JSUCrypt.hash.SHA256()
      domain = JSUCrypt.ECFp.getEcDomainByName("secp256k1")
      affinePoint = new JSUCrypt.ECFp.AffinePoint(Attestation.xPoint, Attestation.yPoint)
      pubkey = new JSUCrypt.key.EcFpPublicKey(256, domain, affinePoint)
      ecsig = new JSUCrypt.signature.ECDSA(sha)
      ecsig.init(pubkey, JSUCrypt.signature.MODE_VERIFY)
      if ecsig.verify(dataToSign, dataSigBytes)
        completion.success()
      else
        completion.failure()
    .fail (err) =>
      error = new ledger.StandardError(Errors.SignatureError, err)
      completion.failure(error)
    .done()
    completion.readonly()

  # Return asynchronosly state. Wait until a state is set.
  # @param [Function] callback Optional argument
  # @return [CompletionClosure]
  getState: (callback=undefined) ->
    completion = new CompletionClosure(callback)
    if @state is States.UNDEFINED
      @once 'state:changed', (e, state) => completion.success(state)
    else
      completion.success(@state)
    completion.readonly()

  # @param [String] pin ASCII encoded
  # @param [Function] callback Optional argument
  # @return [CompletionClosure]
  unlockWithPinCode: (pin, callback=undefined) ->
    throw new ledger.StandardError(Errors.DongleAlreadyUnlock) if @state isnt States.LOCKED
    completion = new CompletionClosure(callback)
    _pin = pin
    @_btchip.verifyPin_async(new ByteString(_pin, ASCII))
    .then =>
      # 19.7. SET OPERATION MODE
      @_sendApdu(new ByteString("E0"+"26"+"01"+"01"+"01", HEX), [0x9000])
      .then =>
        if @firmwareVersion >= ledger.dongle.Firmware.V1_4_13
          # 19.7. SET OPERATION MODE
          @_sendApdu(new ByteString("E0"+"26"+"01"+"00"+"01", HEX), [0x9000]).fail(=> e('Unlock FAIL', arguments)).done()
        @_setState(States.UNLOCKED)
        completion.success()
      .fail (err) =>
        error = new ledger.StandardError(Errors.NotSupportedDongle, err)
        completion.failure(error)
      .done()
    .fail (err) =>
      error = new ledger.StandardError(Error.WrongPinCode, err)
      if err.match(/6faa|63c0/)
        @_setState(States.BLANK)
        error.code = Error.DongleLocked
      else
        @_setState(States.ERROR)
      if data.match(/63c\d/)
        error.retryCount = parseInt(err.substr(-1))
      completion.failure(error)
    .done()
    completion.readonly()

  ###
  @overload setup(pin, callback)
    @param [String] pin
    @param [Function] callback
    @return [CompletionClosure]

  @overload setup(pin, options={}, callback=undefined)
    @param [String] pin
    @param [Object] options
      @options options [String] restoreSeed
      @options options [ByteString] keyMap
    @param [Function] callback
    @return [CompletionClosure]
  ###
  setup: (pin, options={}, callback=undefined) ->
    Errors.throw(Errors.DongleNotBlank) if @state isnt States.BLANK
    [options, callback] = [callback, options] if ! callback && typeof options == 'function'
    [restoreSeed, keyMap] = [options.restoreSeed, options.keyMap]
    completion = new CompletionClosure(callback)

    # Validate seed
    if restoreSeed?
      bytesSeed = new ByteString(restoreSeed, HEX)
      if bytesSeed.length != 32
        e('Invalid seed :', restoreSeed)
        return completion.failure().readonly()

    l("Setup in progress ... please wait")
    @_btchip.setupNew_async(
      0x05,
      BTChip.FEATURE_DETERMINISTIC_SIGNATURE,
      BTChip.VERSION_BITCOIN_MAINNET,
      BTChip.VERSION_BITCOIN_P2SH_MAINNET,
      new ByteString(pin, ASCII),
      undefined,
      keyMap || BTChip.QWERTY_KEYMAP_NEW,
      restoreSeed?,
      bytesSeed
    ).then( ->
      if restoreSeed?
        msg = "Seed restored, please reopen the extension"
      else
        msg = "Plug the dongle into a secure host to read the generated seed, then reopen the extension"
      console.warn(msg)
      @_setState(States.ERROR, msg)
      completion.success()
    ).fail( (err) =>
      error = new ledger.StandardError(Errors.UnknowError, err)
      completion.failure(error)
    ).done()

    completion.readonly()

  # @param [String] path
  # @param [Function] callback Optional argument
  # @return [CompletionClosure]
  getPublicAddress: (path, callback=undefined) ->
    Errors.throw(Errors.DongleLocked, 'Cannot get a public while the key is not unlocked') if @state isnt States.UNLOCKED
    completion = new CompletionClosure(callback)
    @_btchip.getWalletPublicKey_async(path)
    .then (result) =>
      ledger.wallet.HDWallet.instance?.cache?.set [[path, result.bitcoinAddress.value]]
      _.defer -> completion.success(result)
    .fail (err) =>
      if err.indexOf("6982") >= 0 # Pin required
        @_setState(States.LOCKED)
      else if err.indexOf("6985") >= 0 # Error ?
        @_setState(States.BLANK)
      else if err.indexOf("6faa") >= 0
        @_setState(States.ERROR)
      else
        error = new ledger.StandardError(Errors.UnknowError, err)
      _.defer -> completion.failure(error)
    .done()
    completion.readonly()

  # @param [String] message
  # @param [String] path Optional argument
  # @param [Function] callback Optional argument
  # @return [CompletionClosure]
  signMessage: (message, path, callback=undefined) ->
    completion = new CompletionClosure(callback)
    @getPublicAddress(path)
    .then( (address) =>
      message = new ByteString(message, ASCII)
      return @_btchip.signMessagePrepare_async(path, message)
    ).then( =>
      return @_btchip.signMessageSign_async(new ByteString(_pin, ASCII))
    ).then( (sig) =>
      signedMessage = @_convertMessageSignature(address.publicKey, message, sig.signature)
      completion.success(signedMessage)
    ).fail( (error) ->
      completion.failure(error)
    ).done()
    completion.readonly()

  ###
  @overload getBitIdAddress(subpath=undefined, callback=undefined)
    @param [Integer, String] subpath
    @param [Function] callback Optional argument
    @return [CompletionClosure]

  @overload getBitIdAddress(callback)
    @param [Function] callback
    @return [CompletionClosure]
  ###
  getBitIdAddress: (subpath=undefined, callback=undefined) ->
    Errors.throw(Errors.DongleLocked) if @state isnt States.UNLOCKED
    [subpath, callback] = [callback, subpath] if ! callback && typeof subpath == 'function'
    path = ledger.dongle.BitIdRootPath
    path += "/#{subpath}" if subpath?
    @getPublicAddress(path, callback)

  ###
  @overload signMessageWithBitId(message, callback=undefined)
    @param [String] message
    @param [Function] callback Optional argument
    @return [CompletionClosure]

  @overload signMessageWithBitId(message, subpath=undefined, callback=undefined)
    @param [String] message
    @param [Integer, String] subpath Optional argument
    @param [Function] callback Optional argument
    @return [CompletionClosure]

  @see signMessage && getBitIdAddress
  ###
  signMessageWithBitId: (message, subpath=undefined, callback=undefined) ->
    [subpath, callback] = [callback, subpath] if ! callback && typeof subpath == 'function'
    path = ledger.dongle.BitIdRootPath
    path += "/#{subpath}" if subpath?
    @signMessage(message, path, callback)

  # @param [Function] callback Optional argument
  # @return [CompletionClosure]
  randomBitIdAddress: (callback=undefined) ->
    i = sjcl.random.randomWords(1) & 0xffff
    @getBitIdAddress(i, callback)

  # @param [String] pubKey public key, hex encoded.
  # @param [Function] callback Optional argument
  # @return [CompletionClosure] Resolve with a 32 bytes length pairing blob hex encoded.
  initiateSecureScreen: (pubKey, callback=undefined) ->
    Errors.throw(Errors.DongleLocked) if @state != States.UNLOCKED
    Errors.throw(Errors.InvalidArgument, "Invalid pubKey : #{pubKey}") unless pubKey.match(/^[0-9A-Fa-f]{130}$/)
    completion = new CompletionClosure(callback)
    # 19.3. SETUP SECURE SCREEN
    @_sendApdu(new ByteString("E0"+"12"+"01"+"00"+"41"+pubKey, HEX), [0x9000])
    .then( (d) -> completion.success(d.toString()) )
    .fail( (error) -> completion.failure(error) )
    completion.readonly()

  # @param [String] resp challenge response, hex encoded.
  # @param [Function] callback Optional argument
  # @return [CompletionClosure] Resolve if pairing is successful.
  confirmSecureScreen: (resp, callback=undefined) ->
    Errors.throw(Errors.DongleLocked) if @state != States.UNLOCKED
    Errors.throw(Errors.InvalidArgument, "Invalid challenge resp : #{resp}") unless resp.match(/^[0-9A-Fa-f]{32}$/)
    completion = new CompletionClosure(callback)
    # 19.3. SETUP SECURE SCREEN
    @_sendApdu(new ByteString("E0"+"12"+"02"+"00"+"10"+resp, HEX), [0x9000])
    .then( () -> completion.success() )
    .fail( (error) -> completion.failure(error) )
    completion.readonly()

  # @param [String] path
  # @param [Function] callback Optional argument
  # @return [CompletionClosure] Resolve if pairing is successful.
  getExtendedPublicKey: (path, callback=undefined) ->
    Errors.throw(Errors.DongleLocked) if @state != States.UNLOCKED
    completion = new CompletionClosure(callback)
    return completion.success(@_xpubs[path]).readonly() if @_xpubs[path]?
    xpub = new ledger.wallet.ExtendedPublicKey(@, path)
    xpub.initialize () =>
      @_xpubs[path] = xpub
      completion.success(xpub)
    completion.readonly()

  ###
  @param [Array<Object>] inputs
  @param [Array] associatedKeysets
  @param changePath
  @param [String] recipientAddress
  @param [Integer] amount
  @param [Integer] fee
  @param [Integer] lockTime
  @param [Integer] sighashType
  @param [String] authorization hex encoded
  @param [Object] resumeData
  @return [Q.Promise] Resolve with resumeData
  ###
  createPaymentTransaction: (inputs, associatedKeysets, changePath, recipientAddress, amount, fees, lockTime, sighashType, authorization, resumeData) ->
    resumeData = _.clone(resumeData)
    resumeData.scriptData = new ByteString(resumeData.scriptData, HEX)
    resumeData.trustedInputs = (new ByteString(trustedInput, HEX) for trustedInput in resumeData.trustedInputs)
    resumeData.publicKeys = (new ByteString(publicKey, HEX) for publicKey in resumeData.publicKeys)
    @_btchip.createPaymentTransaction_async(
      inputs, associatedKeysets, changePath,
      new ByteString(recipientAddress, ASCII),
      amount.toByteString(),
      fees.toByteString(),
      lockTime && lockTime.toByteString(),
      sighashType && sighashType.toByteString(),
      authorization && new ByteString(authorization, HEX),
      resumeData
    ).then (result) ->
      switch typeof result
        when 'object'
          result.scriptData = result.scriptData.toString(HEX)
          result.trustedInputs = (trustedInput.toString(HEX) for trustedInput in result.trustedInputs)
          result.publicKeys = (publicKey.toString(HEX) for publicKey in result.publicKeys)
          result.authorizationPaired = result.authorizationPaired.toString(HEX) if result.authorizationPaired?
          result.authorizationReference = result.authorizationReference.toString(HEX) if result.authorizationReference?
        when 'string'
          result = result.toString(HEX)
      return result

  ###
  @param [String] input hex encoded
  @return [Object]
    [Array<Byte>] version length is 4
    [Array<Object>] inputs
      [Array<Byte>] prevout length is 36
      [Array<Byte>] script var length
      [Array<Byte>] sequence length is 4
    [Array<Object>] outputs
      [Array<Byte>] amount length is 4
      [Array<Byte>] script var length
    [Array<Byte>] locktime length is 4
  ###
  splitTransaction: (input) ->
    @_btchip.splitTransaction(new ByteString(input.raw, HEX))

  _sendApdu: (cla, ins, p1, p2, opt1, opt2, opt3, wrapScript) -> @_btchip.card.sendApdu_async(cla, ins, p1, p2, opt1, opt2, opt3, wrapScript)

  # @return [Q.Promise] Must be done
  _recoverFirmwareVersion: ->
    @_btchip.getFirmwareVersion_async().then( (result) =>
      firmwareVersion = result['firmwareVersion']
      if (firmwareVersion.byteAt(1) == 0x01) && (firmwareVersion.byteAt(2) == 0x04) && (firmwareVersion.byteAt(3) < 7)
        l "Using old BIP32 derivation"
        @_btchip.setDeprecatedBIP32Derivation()
      if (firmwareVersion.byteAt(1) == 0x01) && (firmwareVersion.byteAt(2) == 0x04) && (firmwareVersion.byteAt(3) < 8)
        l "Using old setup keymap encoding"
        @_btchip.setDeprecatedSetupKeymap()
      @_btchip.setCompressedPublicKeys(result['compressedPublicKeys'])
      @firmwareVersion = firmwareVersion
    ).fail( (error) =>
      e("Firmware version not supported :", error)
    )
  
  # @return [Q.Promise] Must be done
  _recoverOperationMode: ->
    @_btchip.getOperationMode_async().then (mode) =>
      @operationMode = mode

  _setState: (newState, args...) ->
    [@state, oldState] = [@state, newState]
    # Legacy
    @emit 'connected' if newState == States.LOCKED && oldState == States.UNDEFINED
    @emit "state:#{@state}", @state, args...
    @emit 'state:changed', @state

  _convertMessageSignature: (pubKey, message, signature) ->
    bitcoin = new BitcoinExternal()
    hash = bitcoin.getSignedMessageHash(message)
    pubKey = bitcoin.compressPublicKey(pubKey)
    for i in [0...4]
      recoveredKey = bitcoin.recoverPublicKey(signature, hash, i)
      recoveredKey = bitcoin.compressPublicKey(recoveredKey)
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
