
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
  V_LW_1_0_0: 0x20010000010f
  V_LW_1_0_1: 0x200100010110


# Ledger OS pubKey, used for pairing.
Attestation =
  String: "04c370d4013107a98dfef01d6db5bb3419deb9299535f0be47f05939a78b314a3c29b51fcaa9b3d46fa382c995456af50cd57fb017c0ce05e4a31864a79b8fbfd6"
Attestation.Bytes = parseInt(hex, 16) for hex in Attestation.String.match(/\w\w/g)
Attestation.xPoint = Attestation.String.substr(2,64)
Attestation.yPoint = Attestation.String.substr(66)

BetaAttestation =
  String: "04e69fd3c044865200e66f124b5ea237c918503931bee070edfcab79a00a25d6b5a09afbee902b4b763ecf1f9c25f82d6b0cf72bce3faf98523a1066948f1a395f"
BetaAttestation.Bytes = parseInt(hex, 16) for hex in BetaAttestation.String.match(/\w\w/g)
BetaAttestation.xPoint = BetaAttestation.String.substr(2,64)
BetaAttestation.yPoint = BetaAttestation.String.substr(66)


# This path do not need a verified PIN to sign messages.
BitIdRootPath = "0'/0/0xb11e"

Errors = @ledger.errors

$log = -> ledger.utils.Logger.getLoggerByTag("Dongle")

# Populate dongle namespace.
@ledger.dongle ?= {}
_.extend @ledger.dongle,
  States: States
  Firmware: Firmware
  Attestation: Attestation
  BetaAttestation: BetaAttestation
  BitIdRootPath: BitIdRootPath

###
Signals :
  @emit state:changed(States)
  @emit state:locked
  @emit state:unlocked
  @emit state:blank
  @emit state:disconnected
  @emit state:error(args...)
###
class @ledger.dongle.Dongle extends EventEmitter
  Dongle = @

  # @property
  id: undefined
  # @property
  deviceId: undefined
  # @property
  productId: undefined
  # @property [String]
  state: States.UNDEFINED
  # @property [ByteString]
  firmwareVersion: undefined
  # @property [Integer]
  operationMode: undefined

  # @property [BtChip]
  _btchip: undefined
  # @property [Array<ledger.wallet.ExtendedPublicKey>]
  _xpubs: []

  # @private @property [String] pin used to unlock dongle.
  _pin = undefined

  # @private @property [ledger.utils.PromiseQueue] Enqueue btchip calls to prevent multiple call to interfer
  _btchipQueue = undefined

  constructor: (card) ->
    super
    @_xpubs = _.clone(@_xpubs)
    @id = card.deviceId
    @deviceId = card.deviceId
    @productId = card.productId
    _btchipQueue = new ledger.utils.PromiseQueue("Dongle##{@id}")
    @_btchip = new BTChip(card)
    unless @isInBootloaderMode()
      @_recoverFirmwareVersion().then( =>
        #@_recoverOperationMode() It seems useless by now
        # Set dongle state on failure.
        @getPublicAddress("0'/0/0").then( =>
          # @todo Se connecter directement à la carte sans redemander le PIN
          console.warn("Dongle is already unlock ! Case not handle => Pin Code Required.")
          @_setState(States.LOCKED)
        ).catch( (e) -> #console.error(e)
        ).done()
      ).catch( (error) =>
        console.error("Fail to initialize Dongle :", error)
      ).done()
    else
      _.defer => @_setState(States.BLANK)

  # Called when 
  disconnect: () -> @_setState(States.DISCONNECTED)

  # @return [String] Firmware version, 1.0.0 for example.
  getStringFirmwareVersion: -> @firmwareVersion.byteAt(1) + "." + @firmwareVersion.byteAt(2) + "." + @firmwareVersion.byteAt(3)
  
  # @return [Integer] Firmware version, 0x20010000010f for example.
  getIntFirmwareVersion: ->
    parseInt(@firmwareVersion.toString(HEX), 16)

  ###
    Gets the raw version {ByteString} of the dongle.

    @param [Boolean] isInBootLoaderMode Must be true if the current dongle is in bootloader mode.
    @param [Boolean] forceBl Force the call in BootLoader mode
    @param [Function] callback Called once the version is retrieved. The callback must be prototyped like size `(version, error) ->`
    @return [Q.Promise]
  ###
  getRawFirmwareVersion: (isInBootLoaderMode, forceBl=no, callback=undefined) ->
    _btchipQueue.enqueue "getRawFirmwareVersion", =>
      d = ledger.defer(callback)
      apdu = new ByteString((if !isInBootLoaderMode and !forceBl then "E0C4000000" else "F001000000"), HEX)
      @_sendApdu(apdu).then (result) =>
        sw = @_btchip.card.SW
        if !isInBootLoaderMode and !forceBl
          if sw is 0x9000
            d.resolve([result.byteAt(1), (result.byteAt(2) << 16) + (result.byteAt(3) << 8) + result.byteAt(4)])
          else
            # Not initialized now - Retry
            d.resolve @getRawFirmwareVersion(isInBootLoaderMode, yes)
        else
          if sw is 0x9000
            d.resolve([0, (result.byteAt(5) << 16) + (result.byteAt(6) << 8) + result.byteAt(7)])
          else if !isInBootLoaderMode and (sw is 0x6d00 or sw is 0x6e00)
            #  Unexpected - let's say it's 1.4.3
            d.resolve([0, (1 << 16) + (4 << 8) + (3)])
          else
            d.rejectWithError(ledger.errors.UnknowError, "Failed to get version")
      .fail (error) ->
        d.rejectWithError(ledger.errors.UnknowError, error)
      .catch (error) ->
        console.error("Fail to getRawFirmwareVersion :", error)
      .done()
      d.promise

  # @return [Boolean]
  isInBootloaderMode: -> if @productId is 0x1808 or @productId is 0x1807 then yes else no

  # @return [ledger.fup.FirmwareUpdater]
  getFirmwareUpdater: () -> ledger.fup.FirmwareUpdater.instance

  # @return [Q.Promise]
  isFirmwareUpdateAvailable: (callback=undefined) ->
    d = ledger.defer(callback)
    @getFirmwareUpdater().getFirmwareUpdateAvailability(this)
    .then (availablity) ->
      d.resolve(availablity.result is ledger.fup.FirmwareUpdater.FirmwareAvailabilityResult.Update)
    .fail (er) ->
      d.rejectWithError(er)
    .done()
    d.promise

  # @return [Q.Promise]
  isFirmwareOverwriteOrUpdateAvailable: (callback=undefined) ->
    d = ledger.defer(callback)
    @getFirmwareUpdater().getFirmwareUpdateAvailability(this)
    .then (availablity) ->
      d.resolve(availablity.result is ledger.fup.FirmwareUpdater.FirmwareAvailabilityResult.Update or availablity.result is ledger.fup.FirmwareUpdater.FirmwareAvailabilityResult.Overwrite)
    .fail (er) ->
      d.rejectWithError(er)
    .done()
    d.promise

  # Verify that dongle firmware is "official".
  # @param [Function] callback Optional argument
  # @return [Q.Promise]
  isCertified: (callback=undefined) -> @_checkCertification(Attestation, callback)

  isBetaCertified: (callback=undefined) ->
    @_checkCertification(BetaAttestation, callback)

  _checkCertification: (Attestation, callback) ->
    _btchipQueue.enqueue "checkCertification", =>
      d = ledger.defer(callback)
      return d.resolve(true).promise if @getIntFirmwareVersion() < Firmware.V_LW_1_0_0
      randomValues = new Uint32Array(2)
      crypto.getRandomValues(randomValues)
      random = _.str.lpad(randomValues[0].toString(16), 8, '0') + _.str.lpad(randomValues[1].toString(16), 8, '0')
      # 24.2. GET DEVICE ATTESTATION
      @_sendApdu(new ByteString("E0"+"C2"+"00"+"00"+"08"+random, HEX), [0x9000])
      .then (result) =>
        attestation = result.toString(HEX)
        dataToSign = attestation.substring(16,32) + random
        dataSig = attestation.substring(32)
        dataSig = "30" + dataSig.substr(2)
        dataSigBytes = (parseInt(n,16) for n in dataSig.match(/\w\w/g))
        sha = new JSUCrypt.hash.SHA256()
        domain = JSUCrypt.ECFp.getEcDomainByName("secp256k1")
        affinePoint = new JSUCrypt.ECFp.AffinePoint(Attestation.xPoint, Attestation.yPoint)
        pubkey = new JSUCrypt.key.EcFpPublicKey(256, domain, affinePoint)
        ecsig = new JSUCrypt.signature.ECDSA(sha)
        ecsig.init(pubkey, JSUCrypt.signature.MODE_VERIFY)
        if ecsig.verify(dataToSign, dataSigBytes)
          d.resolve(this)
        else
          d.rejectWithError(Errors.DongleNotCertified)
        return
      .fail (err) =>
        d.rejectWithError(Errors.CommunicationError, err)
      .done()
      d.promise

  # Return asynchronously state. Wait until a state is set.
  # @param [Function] callback Optional argument
  # @return [Q.Promise]
  getState: (callback=undefined) ->
    d = ledger.defer(callback)
    if @state is States.UNDEFINED
      @once 'state:changed', (e, state) => d.resolve(state)
    else
      d.resolve(@state)
    d.promise

  # @return [Q.Promise] resolve with a Number, reject with a ledger Error.
  getRemainingPinAttempt: (callback=undefined) ->
    _btchipQueue.enqueue "getRemainingPinAttempt", =>
      d = ledger.defer(callback)
      @_sendApdu(new ByteString("E0228000010000", HEX), [0x9000])
      .catch (statusCode) =>
        if m = statusCode.match(/63c(\d)/)
          d.resolve(parseInt(m[1]))
        else
          d.reject(@_handleErrorCode(statusCode))
      .done()
      d.promise

  # @param [String] pin ASCII encoded
  # @param [Function] callback Optional argument
  # @return [Q.Promise]
  unlockWithPinCode: (pin, callback=undefined) ->
    Errors.throw(Errors.DongleAlreadyUnlock) if @state isnt States.LOCKED
    _btchipQueue.enqueue "unlockWithPinCode", =>
      d = ledger.defer(callback)
      _pin = pin
      @_btchip.verifyPin_async(new ByteString(_pin, ASCII))
      .then =>
        # 19.7. SET OPERATION MODE
        @_sendApdu(0xE0, 0x26, 0x01, 0x01, new ByteString(Convert.toHexByte(0x01), HEX), [0x9000])
        .then =>
          if @getIntFirmwareVersion() >= Firmware.V1_4_13
            # 19.7. SET OPERATION MODE
            mode = if @getIntFirmwareVersion() >= Firmware.V_LW_1_0_0 then 0x02 else 0x01
            @_sendApdu(0xE0, 0x26, mode, 0x00, new ByteString(Convert.toHexByte(0x01), HEX), [0x9000]).fail(=> e('Unlock FAIL', arguments)).done()
          @_setState(States.UNLOCKED)
          d.resolve()
        .fail (err) =>
          error = Errors.new(Errors.NotSupportedDongle, err)
          console.log("unlockWithPinCode 2 fail :", err)
          d.reject(error)
        .catch (error) ->
          console.error("Fail to unlockWithPinCode 2 :", error)
        .done()
      .fail (err) =>
        console.error("Fail to unlockWithPinCode 1 :", err)
        error = @_handleErrorCode(err)
        d.reject(error)
      .catch (error) ->
        console.error("Fail to unlockWithPinCode 1 :", error)
      .done()
      d.promise

  lock: () ->
    if @state isnt ledger.dongle.States.BLANK and @state?
      @_setState(States.LOCKED)

  ###
  @overload setup(pin, callback)
    @param [String] pin
    @param [Function] callback
    @return [Q.Promise]

  @overload setup(pin, options={}, callback=undefined)
    @param [String] pin
    @param [String] restoreSeed
      @options options [String] restoreSeed
      @options options [ByteString] keyMap
    @param [Function] callback
    @return [Q.Promise]
  ###
  setup: (pin, restoreSeed, callback=undefined) ->
    Errors.throw(Errors.DongleNotBlank) if @state isnt States.BLANK
    [restoreSeed, callback] = [callback, restoreSeed] if ! callback && typeof restoreSeed == 'function'
    _btchipQueue.enqueue "setup", =>
      d = ledger.defer(callback)

      # Validate seed
      if restoreSeed?
        bytesSeed = new ByteString(restoreSeed, HEX)
        if bytesSeed.length != 64
          e('Invalid seed :', restoreSeed)
          return d.reject().promise

      l("Setup in progress ... please wait")
      @_btchip.setupNew_async(
        BTChip.MODE_WALLET,
        BTChip.FEATURE_DETERMINISTIC_SIGNATURE | BTChip.FEATURE_NO_2FA_P2SH,
        BTChip.VERSION_BITCOIN_MAINNET,
        BTChip.VERSION_BITCOIN_P2SH_MAINNET,
        new ByteString(pin, ASCII),
        undefined,
        BTChip.QWERTY_KEYMAP_NEW,
        restoreSeed?,
        bytesSeed
      ).then( =>
        if restoreSeed?
          msg = "Seed restored, please reopen the extension"
        else
          msg = "Plug the dongle into a secure host to read the generated seed, then reopen the extension"
        console.warn(msg)
        @_setState(States.ERROR, msg)
        d.resolve()
      ).fail( (err) =>
        error = Errors.new(Errors.UnknowError, err)
        d.reject(error)
      ).catch( (error) ->
        console.error("Fail to setup :", error)
      ).done()

      d.promise

  # @param [String] path
  # @param [Function] callback Optional argument
  # @return [Q.Promise]
  getPublicAddress: (path, callback=undefined) ->
    #l path
    #l new Error().stack
    Errors.throw(Errors.DongleLocked, 'Cannot get a public while the key is not unlocked') if @state isnt States.UNLOCKED && @state isnt States.UNDEFINED
    _btchipQueue.enqueue "getPublicAddress", =>
      d = ledger.defer(callback)
      @_btchip.getWalletPublicKey_async(path)
      .then (result) =>
        ledger.wallet.Wallet.instance?.cache?.set [[path, result.bitcoinAddress.value]]
        _.defer -> d.resolve(result)
      .fail (err) =>
        error = @_handleErrorCode(err)
        _.defer -> d.reject(error)
      .catch (error) ->
        console.error("Fail to getPublicAddress :", error)
      .done()
      d.promise

  # @param [String] message
  # @param [String] path Optional argument
  # @param [Function] callback Optional argument
  # @return [Q.Promise]
  signMessage: (message, {path, pubKey}, callback=undefined) ->
    if ! pubKey?
      @getPublicAddress(path).then((address) => console.log("address=", address); @signMessage(message, path: path, pubKey: address.publicKey, callback))
    else
      _btchipQueue.enqueue "signMessage", =>
        d = ledger.defer(callback)
        message = new ByteString(message, ASCII)
        @_btchip.signMessagePrepare_async(path, message)
        .then =>
          return @_btchip.signMessageSign_async(new ByteString(_pin, ASCII))
        .then (sig) =>
          signedMessage = @_convertMessageSignature(pubKey, message, sig.signature)
          d.resolve(signedMessage)
        .catch (error) ->
          console.error("Fail to signMessage :", error)
          d.reject(error)
        .done()
        d.promise

  # @param [String] pubKey public key, hex encoded.
  # @param [Function] callback Optional argument
  # @return [Q.Promise] Resolve with a 32 bytes length pairing blob hex encoded.
  initiateSecureScreen: (pubKey, callback=undefined) ->
    _btchipQueue.enqueue "initiateSecureScreen", =>
      d = ledger.defer(callback)
      if @state != States.UNLOCKED
        d.rejectWithError(Errors.DongleLocked)
      else if ! pubKey.match(/^[0-9A-Fa-f]{130}$/)?
        d.rejectWithError(Errors.InvalidArgument, "Invalid pubKey : #{pubKey}")
      else
        # 19.3. SETUP SECURE SCREEN
        @_sendApdu(new ByteString("E0"+"12"+"01"+"00"+"41"+pubKey, HEX), [0x9000])
        .then (c) ->
          l 'initiateSecureScreen', c
          d.resolve(c.toString())
        .fail (error) -> d.reject(error)
        .done()
      d.promise

  # @param [String] resp challenge response, hex encoded.
  # @param [Function] callback Optional argument
  # @return [Q.Promise] Resolve if pairing is successful.
  confirmSecureScreen: (resp, callback=undefined) ->
    _btchipQueue.enqueue "confirmSecureScreen", =>
      d = ledger.defer(callback)
      if @state != States.UNLOCKED
        d.rejectWithError(Errors.DongleLocked)
      else if ! resp.match(/^[0-9A-Fa-f]{32}$/)?
        d.rejectWithError(Errors.InvalidArgument, "Invalid challenge resp : #{resp}")
      else
        # 19.3. SETUP SECURE SCREEN
        @_sendApdu(new ByteString("E0"+"12"+"02"+"00"+"10"+resp, HEX), [0x9000])
        .then () ->
          l 'confirmSecureScreen'
          d.resolve()
        .fail (error) -> d.reject(error)
        .done()
      d.promise

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
  createPaymentTransaction: (inputs, associatedKeysets, changePath, recipientAddress, amount, fees, lockTime, sighashType, authorization, resumeData) ->
    if resumeData?
      resumeData = _.clone(resumeData)
      resumeData.scriptData = new ByteString(resumeData.scriptData, HEX)
      resumeData.trustedInputs = (new ByteString(trustedInput, HEX) for trustedInput in resumeData.trustedInputs)
      resumeData.publicKeys = (new ByteString(publicKey, HEX) for publicKey in resumeData.publicKeys)
    _btchipQueue.enqueue "createPaymentTransaction", =>
      @_btchip.createPaymentTransaction_async(
        inputs, associatedKeysets, changePath,
        new ByteString(recipientAddress, ASCII),
        amount.toByteString(),
        fees.toByteString(),
        lockTime && new ByteString(Convert.toHexInt(lockTime), HEX),
        sighashType && new ByteString(Convert.toHexInt(sighashType), HEX),
        authorization && new ByteString(authorization, HEX),
        resumeData
      )
      .then( (result) ->
        if result instanceof ByteString
          result = result.toString(HEX)
        else
          result.scriptData = result.scriptData.toString(HEX)
          result.trustedInputs = (trustedInput.toString(HEX) for trustedInput in result.trustedInputs)
          result.publicKeys = (publicKey.toString(HEX) for publicKey in result.publicKeys)
          result.authorizationPaired = result.authorizationPaired.toString(HEX) if result.authorizationPaired?
          result.authorizationReference = result.authorizationReference.toString(HEX) if result.authorizationReference?
        return result
      )

  formatP2SHOutputScript: (transaction) ->
    @_btchip.formatP2SHOutputScript(transaction)

  ###
  @return [Q.Promise]
  ###
  signP2SHTransaction: (inputs, scripts, numOutputs, output, paths) ->
    _btchipQueue.enqueue "signP2SHTransaction", =>
      @_btchip.signP2SHTransaction_async(inputs, scripts, numOutputs, output, paths)

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
    _btchipQueue.enqueue "recoverFirmwareVersion", =>
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
    _btchipQueue.enqueue "recoverOperationMode", =>
      @_btchip.getOperationMode_async().then (mode) =>
        @operationMode = mode

  _setState: (newState, args...) ->
    [@state, oldState] = [newState, @state]
    @emit "state:#{@state}", @state, args...
    @emit 'state:changed', @state

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
    return error

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
