
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

Firmwares = ledger.dongle.Firmwares

Attestations = {}

class Attestation

  xPoint: null
  yPoint: null
  Bytes: null
  BatchId: null
  DerivationId: null

  constructor: (batchId, derivationId, value) ->
    if _(this).isKindOf(Attestation)
      @BatchId = batchId
      @DerivationId = derivationId
      @Id = Convert.toHexInt(batchId) + Convert.toHexInt(derivationId)
      @String = value
      @Bytes = parseInt(hex, 16) for hex in @String.match(/\w\w/g)
      @xPoint = @String.substr(2,64)
      @yPoint = @String.substr(66)
      Attestations[@Id] = this
    else
      new Attestation(batchId, derivationId, value)

  isBeta: -> @BatchId is 0
  isProduction: -> !@isBeta()

  getAttestationId: -> new ByteString(@Id, HEX)

Attestation(0, 1, "04e69fd3c044865200e66f124b5ea237c918503931bee070edfcab79a00a25d6b5a09afbee902b4b763ecf1f9c25f82d6b0cf72bce3faf98523a1066948f1a395f")
Attestation(1, 1, "04223314cdffec8740150afe46db3575fae840362b137316c0d222a071607d61b2fd40abb2652a7fea20e3bb3e64dc6d495d59823d143c53c4fe4059c5ff16e406")
Attestation(2, 1, "04c370d4013107a98dfef01d6db5bb3419deb9299535f0be47f05939a78b314a3c29b51fcaa9b3d46fa382c995456af50cd57fb017c0ce05e4a31864a79b8fbfd6")


# This path do not need a verified PIN to sign messages.
BitIdRootPath = "0'/0/0xb11e"

Errors = @ledger.errors

$log = -> ledger.utils.Logger.getLoggerByTag("Dongle")

# Populate dongle namespace.
@ledger.dongle ?= {}
_.extend @ledger.dongle,
  States: States
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

  # @private [BtChip]
  _btchip: undefined
  # @private [Array<ledger.wallet.ExtendedPublicKey>]
  _xpubs: []

  # @private @property [String] pin used to unlock dongle.
  _pin: undefined

  # @private @property [ledger.utils.PromiseQueue] Enqueue btchip calls to prevent multiple call to interfer
  _btchipQueue = undefined

  constructor: (card) ->
    super
    @_attestation = null
    @_xpubs = _.clone(@_xpubs)
    @id = card.deviceId
    @deviceId = card.deviceId
    @productId = card.productId
    _btchipQueue = new ledger.utils.PromiseQueue("Dongle##{@id}")
    @_btchip = new BTChip(card)

  # Recovers dongle firmware version and initialize current state
  connect: (forceBootloader = no, callback = undefined) ->
    # Recover firmware version
      # Create firmware info object
      # Determine state (setup|locked|unlocked|blank)
        # Resolve
    @_forceBl = forceBootloader
    @state = States.UNDEFINED
    unless @isInBootloaderMode()
      @_recoverFirmwareVersion().then =>
        if @getFirmwareInformation().hasSetupFirmwareSupport() && !@getFirmwareInformation().hasScreenAndButton()
          @getRemainingPinAttempt().then =>
            @_setState(States.LOCKED)
            States.LOCKED
          .fail (error) =>
            @_setState(States.BLANK)
            States.BLANK
        else
          # Nano S, Blue
          if @getFirmwareInformation().hasScreenAndButton()
            @_setState States.UNLOCKED
            States.UNLOCKED
          else
            @_sendApdu(0xE0, 0x40, 0x00, 0x00, 0x05, 0x01).then (result) =>
              switch @getSw()
                when 0x9000, 0x6982
                  @_setState States.LOCKED
                  States.LOCKED
                when 0x6985
                  configureBlank = =>
                    @_setState(States.BLANK)
                    States.BLANK
                  # Check restore
                  if @getFirmwareInformation().hasSubFirmwareSupport() and @getFirmwareInformation().hasOperationFirmwareSupport()
                    @restoreSetup().then =>
                      @_setState States.LOCKED
                      States.LOCKED
                    .catch => do configureBlank
                  else
                    do configureBlank
                when 0x6faa
                  throw "Invalid statue - 0x6faa"
      .catch (error) =>
        console.error("Fail to initialize Dongle :", error)
        @_setState(States.ERROR)
        throw error
    else
      ledger.delay(0).then(=> @_setState States.BLANK).then(-> States.BLANK)

  setCoinVersion: (p2pkhVersion, p2shVersion, callback = undefined) ->
    d = ledger.defer(callback)
    @_sendApdu(new ByteString("E014000002#{("0" + p2pkhVersion.toString(16)).substr(-2)}#{("0" + p2shVersion.toString(16)).substr(-2)}", HEX)).then ->
      d.resolve()
    .fail (e) ->
      d.reject(e)
    d.promise

  getCoinVersion: (callback = undefined) ->
    d = ledger.defer(callback)
    d.resolve(
      @_sendApdu(new ByteString("E016000000", HEX)).then (result) =>
        message = result.bytes(3, result.byteAt(2))
        short = result.bytes(3 + message.length + 1, result.byteAt(3 + message.length))
        {P2PKH: result.byteAt(0), P2SH: result.byteAt(1), message: "#{message} signed message:\n", short: short}
      .fail =>
        l "FAILED"
        {P2PKH: ledger.bitcoin.Networks.bitcoin.version.regular, P2SH: ledger.bitcoin.Networks.bitcoin.version.P2SH, message: "Bitcoin signed message:\n", short: 'BTC'}
    )
    d.promise

  getFirmwareInformation: -> @_firmwareInformation

  getSw: -> @_btchip.card.SW

  # Called when 
  disconnect: ->
    @_btchip.card.disconnect()
    @_setState(States.DISCONNECTED)

  # @return [String] Firmware version, 1.0.0 for example.
  getStringFirmwareVersion: -> Try(=> @getFirmwareInformation().getStringFirmwareVersion()).getOrElse('unknown')
  
  # @return [Integer] Firmware version, 0x20010000010f for example.
  getIntFirmwareVersion: -> @getFirmwareInformation().getIntFirmwareVersion()

  ###
    Gets the raw version {ByteString} of the dongle.

    @param [Boolean] isInBootLoaderMode Must be true if the current dongle is in bootloader mode.
    @param [Boolean] forceBl Force the call in BootLoader mode
    @param [Function] callback Called once the version is retrieved. The callback must be prototyped like size `(version, error) ->`
    @return [Q.Promise]
  ###
  getRawFirmwareVersion: (isInBootLoaderMode, forceBl=no, checkHiddenReloader = no, callback=undefined) ->
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
            # Bootloader ok, let's see if hidden reloader
            result2 = result
            apdu = new ByteString("E001000000", HEX)
            if checkHiddenReloader
              @_sendApdu(apdu).then (result) =>
                if @_btchip.card.SW isnt 0x9000
                  result = result2
                d.resolve([0, (result.byteAt(5) << 16) + (result.byteAt(6) << 8) + result.byteAt(7)])
              .fail ->
                result = result2
                d.resolve([0, (result.byteAt(5) << 16) + (result.byteAt(6) << 8) + result.byteAt(7)])
            else
              result = result2
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
  isInBootloaderMode: -> if @productId is 0x1808 or @productId is 0x1807 or @_forceBl then yes else no

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
  isCertified: (callback=undefined) -> @_checkCertification(no, callback)

  isBetaCertified: (callback=undefined) -> @_checkCertification(yes, callback)

  _checkCertification: (isBeta, callback = undefined) ->
    _btchipQueue.enqueue "checkCertification", =>
      d = ledger.defer(callback)
      return d.resolve(true).promise if @getIntFirmwareVersion() < ledger.dongle.Firmwares.V_L_1_0_0
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
        if isBeta
          Attestation = Attestations["0000000000000001"]
        else
          Attestation = Attestations[result.bytes(0, 8).toString()]
        affinePoint = new JSUCrypt.ECFp.AffinePoint(Attestation.xPoint, Attestation.yPoint)
        pubkey = new JSUCrypt.key.EcFpPublicKey(256, domain, affinePoint)
        ecsig = new JSUCrypt.signature.ECDSA(sha)
        ecsig.init(pubkey, JSUCrypt.signature.MODE_VERIFY)
        if ecsig.verify(dataToSign, dataSigBytes)
          @_attestation = Attestation
          d.resolve(this)
        else
          d.rejectWithError(Errors.DongleNotCertified)
        return
      .fail (err) =>
        d.rejectWithError(Errors.CommunicationError, err)
      .done()
      d.promise

  getAttestation: -> @_attestation

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
    Errors.throw(Errors.DongleAlreadyUnlock) if @state is States.UNLOCKED
    _btchipQueue.enqueue "unlockWithPinCode", =>
      d = ledger.defer(callback)
      @_pin = pin
      @_btchip.verifyPin_async(new ByteString(@_pin, ASCII))
      .then =>
        if @getFirmwareInformation().hasSubFirmwareSupport() and @getFirmwareInformation().hasSetupFirmwareSupport()
          d.resolve()
          return
        # 19.7. SET OPERATION MODE
        @_sendApdu(0xE0, 0x26, 0x01, 0x01, 0x01, 0x01, [0x9000])
        .then =>
          if @getIntFirmwareVersion() >= Firmwares.V_B_1_4_13
            # 19.7. SET OPERATION MODE
            mode = if @getIntFirmwareVersion() >= Firmwares.V_L_1_0_0 then 0x02 else 0x01
            @_sendApdu(0xE0, 0x26, mode, 0x00, 0x01, 0x01, [0x9000]).fail(=> e('Unlock FAIL', arguments)).done()
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

      @_btchip.setupNew_async(
        BTChip.MODE_WALLET,
        BTChip.FEATURE_DETERMINISTIC_SIGNATURE | BTChip.FEATURE_NO_2FA_P2SH,
        ledger.config.network.version.regular,
        ledger.config.network.version.P2SH,
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

  setupSwappedBip39: (pin, userEntropy = undefined, callback = undefined) -> @_setupSwappedBip39({pin, userEntropy, callback})

  restoreSwappedBip39: (pin, restoreSeed, callback = undefined) -> @_setupSwappedBip39({pin, restoreSeed, callback})

  _setupSwappedBip39: ({pin, userEntropy, restoreSeed, callback}) ->
    Errors.throw(Errors.DongleNotBlank) if @state isnt States.BLANK
    userEntropy ||= ledger.bitcoin.bip39.generateEntropy()
    if restoreSeed?
      indexes = ledger.bitcoin.bip39.mnemonicPhraseToWordIndexes(restoreSeed)
      restoreSeed = (Convert.toHexShort(index) for index in indexes).join('')
    d = ledger.defer(callback)
    @_btchip.setupNew_async(
      BTChip.MODE_WALLET,
      BTChip.FEATURE_DETERMINISTIC_SIGNATURE | BTChip.FEATURE_NO_2FA_P2SH,
      ledger.config.network.version.regular,
      ledger.config.network.version.P2SH,
      new ByteString(pin, ASCII),
      undefined,
      undefined,
      false,
      new ByteString(restoreSeed or userEntropy, HEX),
      undefined, !restoreSeed?, restoreSeed?
    ).then (result) =>
      mnemonic = []
      for i in [0...24]
        wordIndex = (result['swappedMnemonic'].byteAt(2 * i) << 8) + (result['swappedMnemonic'].byteAt(2 * i + 1))
        mnemonic.push ledger.bitcoin.bip39.wordlist[wordIndex]
      d.resolve(_.extend(result, mnemonic: mnemonic))
    .fail (error) =>
      d.reject(error)
    .done()
    d.promise

  setupFinalizeBip39: (callback = undefined) ->
    ledger.defer(callback).resolve(@_btchip.setupFinalizeBip39_async()).promise

  restoreFinalizeBip29: (callback = undefined) ->
    ledger.defer(callback).resolve(@_btchip.setupRecovery_async()).promise

  restoreSetup: (callback = undefined) -> @_sendApdu(0xE0, 0x20, 0xFF, 0x00, 0x01, 0x00, [0x9000]).then(callback or _.noop)

  isSwappedBip39FeatureEnabled: ->
    @setupSwappedBip39("0000").then(-> yes).fail(-> no)

  # @param [String] path
  # @param [Function] callback Optional argument
  # @return [Q.Promise]
  getPublicAddress: (path, callback=undefined) ->
    Errors.throw(Errors.DongleLocked, 'Cannot get a public while the key is not unlocked') if @state isnt States.UNLOCKED && @state isnt States.UNDEFINED
    _btchipQueue.enqueue "getPublicAddress", =>
      d = ledger.defer(callback)
      @_btchip.getWalletPublicKey_async(path)
      .then (result) =>
        #ledger.wallet.Wallet.instance?.cache?.set [[path, result.bitcoinAddress.value]]
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
  signMessage: (message, {prefix, path, pubKey}, callback=undefined) ->
    prefix ?= '\x18Bitcoin Signed Message:\n'
    if ! pubKey?
      @getPublicAddress(path).then((address) => console.log("address=", address); @signMessage(message, path: path, pubKey: address.publicKey, callback))
    else
      _btchipQueue.enqueue "signMessage", =>
        d = ledger.defer(callback)
        message = new ByteString(message, ASCII)
        @_btchip.signMessagePrepare_async(path, message)
        .then =>
          return @_btchip.signMessageSign_async(if (@_pin?) then new ByteString(@_pin, ASCII) else new ByteString("0000", ASCII))
        .then (sig) =>
          signedMessage = @_convertMessageSignature(pubKey, message, prefix, sig.signature)
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
  createPaymentTransaction: (inputs, associatedKeysets, changePath, recipientAddress, amount, fees, data, lockTime, sighashType, authorization, resumeData) ->
    if resumeData?
      resumeData = _.clone(resumeData)
      resumeData.scriptData = new ByteString(resumeData.scriptData, HEX)
      resumeData.trustedInputs = (new ByteString(trustedInput, HEX) for trustedInput in resumeData.trustedInputs)
      resumeData.publicKeys = (new ByteString(publicKey, HEX) for publicKey in resumeData.publicKeys)
    if @getFirmwareInformation().isUsingInputFinalizeFull()
      @_createPaymentTransactionNew(inputs, associatedKeysets, changePath, recipientAddress, amount, fees, lockTime, sighashType, authorization, data, resumeData)
    else
      @_createPaymentTransaction(inputs, associatedKeysets, changePath, recipientAddress, amount, fees, lockTime, sighashType, authorization, resumeData)

  _createPaymentTransaction: (inputs, associatedKeysets, changePath, recipientAddress, amount, fees, lockTime, sighashType, authorization, resumeData) ->
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

  _createPaymentTransactionNew: (inputs, associatedKeysets, changePath, recipientAddress, amount, fees, lockTime, sighashType, authorization, data, resumeData) ->
    @getPublicAddress(changePath).then (result) =>
      changeAddress = result.bitcoinAddress.toString(ASCII)
      inputAmounts = do =>
        for [prevTx, index], i in inputs
          ledger.Amount.fromSatoshi(prevTx.outputs[index].amount)

      totalInputAmount = ledger.Amount.fromSatoshi(0)
      for inputAmount in inputAmounts
        totalInputAmount = totalInputAmount.add(inputAmount)

      changeAmount = totalInputAmount.subtract(amount).subtract(fees)
      changePath = undefined if changeAmount.lte(0)

      VI = @_btchip.createVarint.bind(@_btchip)
      OP_DUP = new ByteString('76', HEX)
      OP_HASH160 = new ByteString('A9', HEX)
      OP_EQUAL = new ByteString('87', HEX)
      OP_EQUALVERIFY = new ByteString('88', HEX)
      OP_CHECKSIG = new ByteString('AC', HEX)
      OP_RETURN = new ByteString('6A', HEX)

      ###
        Create the output script
        Count (VI) | Value (8) | PkScript (var) | ....
      ###

      PkScript = (address) =>
        hash160WithNetwork = ledger.bitcoin.addressToHash160WithNetwork(address)
        hash160 = hash160WithNetwork.bytes(1, hash160WithNetwork.length - 1) #ledger.bitcoin.addressToHash160(address)
        return P2shScript(hash160) if hash160WithNetwork.byteAt(0) is ledger.config.network.version.P2SH
        script =
          OP_DUP
          .concat(OP_HASH160)
          .concat(new ByteString(Convert.toHexByte(hash160.length), HEX))
          .concat(hash160)
          .concat(OP_EQUALVERIFY)
          .concat(OP_CHECKSIG)
        VI(script.length).concat(script)

      P2shScript = (hash160) =>
        script =
          OP_HASH160
          .concat(new ByteString(Convert.toHexByte(hash160.length), HEX))
          .concat(hash160)
          .concat(OP_EQUAL)
        VI(script.length).concat(script)

      OpReturnScript = (data) =>
        script =
          OP_RETURN
          .concat(new ByteString(Convert.toHexByte(data.length / 2), HEX))
          .concat(new ByteString(data, HEX))
        VI(script.length).concat(script)


      numberOfOutputs = 1 + (if (changeAmount.lte(0)) then 0 else 1) + (if (data?) then 1 else 0)
      outputScript =
        VI(numberOfOutputs)
        .concat(amount.toScriptByteString())
        .concat(PkScript(recipientAddress))

      if changeAmount.gt(0)
        outputScript = outputScript
          .concat(changeAmount.toScriptByteString())
          .concat(PkScript(changeAddress))
      if data?
        outputScript = outputScript
          .concat(ledger.Amount.fromSatoshi(0).toScriptByteString())
          .concat(OpReturnScript(data))

      task = =>
        @_btchip.createPaymentTransactionNew_async(
          inputs, associatedKeysets, changePath,
          outputScript,
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
            result.encryptedOutputScript = result.encryptedOutputScript?.toString(HEX)
          return result
        )
      _btchipQueue.enqueue("createPaymentTransaction", task, (if (@getFirmwareInformation().hasScreenAndButton()) then 72000000 else undefined))
    .fail (er) ->
      e er

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

  _sendApdu: (args...) ->
    apdu = new ByteString('', HEX)
    swCheck = undefined
    for arg, index in args
      if arg instanceof ByteString
        apdu = apdu.concat(arg)
      else if index is args.length - 1 and _.isArray(arg)
        swCheck = arg
      else
        apdu = apdu.concat(new ByteString((if _.isNumber(arg) then Convert.toHexByte(arg) else arg.replace(/\s/g, '')), HEX))
    @_btchip.card.sendApdu_async(apdu, swCheck)

  # @return [Q.Promise] Must be done
  _recoverFirmwareVersion: ->
    _btchipQueue.enqueue "recoverFirmwareVersion", =>
      @_sendApdu('E0 C4 00 00 00 08').then (version) =>
        firmware = new ledger.dongle.FirmwareInformation(this, version)
        if firmware.isUsingInputFinalizeFull()
          @_btchip.setUntrustedHashTransactionInputFinalizeFull()
        if firmware.isUsingDeprecatedBip32Derivation()
          @_btchip.setDeprecatedBIP32Derivation()
        if firmware.isUsingDeprecatedSetupKeymap()
          @_btchip.setDeprecatedSetupKeymap()
        @_btchip.setCompressedPublicKeys(firmware.hasCompressedPublicKeysSupport())
        @_firmwareInformation = firmware
      .fail (error) =>
        e("Firmware version not supported :", error)
        throw error

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

  _convertMessageSignature: (pubKey, message, prefix, signature) ->
    bitcoin = new BitcoinExternal()
    hash = bitcoin.getSignedMessageHash(message, prefix)
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
