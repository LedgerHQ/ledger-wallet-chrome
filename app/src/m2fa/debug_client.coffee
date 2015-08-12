
# Listen and log each event + add conveniant methods to simulate mobile/server.
class @ledger.m2fa.DebugClient extends ledger.m2fa.Client
  constructor: (pairingId, baseUrl) ->
    @constructor.BASE_URL = baseUrl || "ws://192.168.2.107:8080/2fa/channels"
    super(pairingId || "holymacaroni2")
    @pubKey = "04"+"78c0837ded209265ea8131283585f71c5bddf7ffafe04ccddb8fe10b3edc7833"+"d6dee70c3b9040e1a1a01c5cc04fcbf9b4de612e688d09245ef5f9135413cc1d"
    @privKey = "80"+"dbd39adafe3a007706e61a17e0c56849146cfe95849afef7ede15a43a1984491"+"7e960af3"
    @attestationKey = "04"+"e69fd3c044865200e66f124b5ea237c918503931bee070edfcab79a00a25d6b5"+"a09afbee902b4b763ecf1f9c25f82d6b0cf72bce3faf98523a1066948f1a395f"
    @bitAddress = "1M2FAtNbADDd3Gib6Ggvt6R7A9GiidrXMS"
    @cardSeed = "7d0f4cc77408c9e7fb0610aa1c16f117"
    @_generateSessionKey()
    @_computeKeyCard()

    @on 'm2fa.room.joined', => console.log("%c[M2FA][#{@pairingId}] Room joined", "color: #888888")
    @on 'm2fa.room.left', => console.log("%c[M2FA][#{@pairingId}] Room left", "color: #888888")
    @on 'm2fa.connect', => console.log("%c[M2FA][#{@pairingId}] Connection", "color: #888888")
    @on 'm2fa.disconnect', => console.log("%c[M2FA][#{@pairingId}] Diconnection", "color: #888888")
    @on 'm2fa.message', (e,data) => console.log("%c[M2FA][#{@pairingId}] #{data.type} message :", "color: #888888", data, e)
    @on 'm2fa.challenge.sended', (e,challenge) =>
      console.log("%c[M2FA][#{@pairingId}] challenge :", "color: #888888", challenge, e)
      @lastChallenge = challenge
    @on 'm2fa.pairing.confirmed', (e,success) => console.log("%c[M2FA][#{@pairingId}] pairing.confirmed", "color: #888888", success, e)
    @on 'm2fa.pairing.rejected', => console.log("%c[M2FA][#{@pairingId}] pairing.confirmed", "color: #888888")
    @on 'm2fa.request.sended', (e,requestBlob) =>
      console.log("%c[M2FA][#{@pairingId}] request :", "color: #888888", requestBlob, e)
      @lastRequest = requestBlob

  identify: -> @_onIdentify({public_key: @pubKey})
  challenge: (data) -> @_onChallenge({data: data || @_computeChallenge()})
  accept: -> @_onAccept()
  repeat: -> @_onRepeat()
  respond: (pin) -> @_onResponse({pin: pin || @_computeResponse().pin})

  # @param {String} challenge hex encoded
  # @return {Array} The resp hex encoded + the pairingKey hex encoded
  _computeChallenge: (challenge=@lastChallenge) ->
    l "%c[_computeChallenge] challenge=", "color: #888888", challenge
    [nonce, blob] = [challenge[0...16], challenge[16..-1]]
    l "%c[_computeChallenge] nonce=", "color: #888888", nonce, ", blob=", blob
    bytes = @_decryptChallenge(blob)
    l "%c[_computeChallenge] bytes=", "color: #888888", JSUCrypt.utils.byteArrayToHexStr(bytes)
    [cardChallenge, pairingKey] = [bytes[0...4], bytes[4...20]]
    @pairingKey = JSUCrypt.utils.byteArrayToHexStr(pairingKey)
    l "%c[_computeChallenge] cardChallenge=", "color: #888888", JSUCrypt.utils.byteArrayToHexStr(cardChallenge), ", pairingKey=", @pairingKey
    cardResp = JSUCrypt.utils.byteArrayToHexStr(@_prompt(cardChallenge))
    l "%c[_computeChallenge] cardResp=", "color: #888888", cardResp
    resp = JSUCrypt.utils.byteArrayToHexStr(@_cryptChallenge(nonce + cardResp + "00000000"))
    return [resp, @pairingKey]

  # @param {String} blob an hex encoded blob
  # @return a byteArray
  _decryptChallenge: (blob) ->
    cipher = new JSUCrypt.cipher.DES(JSUCrypt.padder.None, JSUCrypt.cipher.MODE_CBC)
    key = new JSUCrypt.key.DESKey(@sessionKey)
    cipher.init(key, JSUCrypt.cipher.MODE_DECRYPT)
    cipher.update(blob)

  # @param {String} blob an hex encoded blob
  # @return byteArray
  _cryptChallenge: (blob) ->
    cipher = new JSUCrypt.cipher.DES(JSUCrypt.padder.None, JSUCrypt.cipher.MODE_CBC)
    key = new JSUCrypt.key.DESKey(@sessionKey)
    cipher.init(key, JSUCrypt.cipher.MODE_ENCRYPT)
    cipher.update(blob)

  # @param [Array] chars byteArray
  # @return byteArray
  _prompt: (chars) ->
    @_keyCard[c] for c in chars

  _computeKeyCard: ->
    throw "Invalid card seed" if @cardSeed.length != 32
    key = new JSUCrypt.key.DESKey(@cardSeed)
    cipher = new JSUCrypt.cipher.DES(JSUCrypt.padder.None, JSUCrypt.cipher.MODE_CBC)
    cipher.init(key, JSUCrypt.cipher.MODE_ENCRYPT)
    data = (Convert.toHexByte(i) for i in [0..0x50]).join('')
    @_keyCard = for i in cipher.update(data)
      [a, b] = (parseInt(n,16) for n in Convert.toHexByte(i).split(''))
      a ^ b

  _generateSessionKey: ->
    # secp256k1
    ecdhdomain = JSUCrypt.ECFp.getEcDomainByName("secp256k1")
    ecdhprivkey = new JSUCrypt.key.EcFpPrivateKey(256, ecdhdomain, @privKey.match(/^(\w{2})(\w{64})(01)?(\w{8})$/)[2])
    ecdh = new JSUCrypt.keyagreement.ECDH_SVDP(ecdhprivkey)
    aKey = @attestationKey.match(/^(\w{2})(\w{64})(\w{64})$/)
    secret = ecdh.generate(new JSUCrypt.ECFp.AffinePoint(aKey[2], aKey[3], ecdhdomain.curve))
    @sessionKey = (Convert.toHexByte(secret[i] ^ secret[16+i]) for i in [0...16]).join('')
    l("%c[M2FA][#{@pairingId}] sessionKey=", "color: #888888", @sessionKey)
    @sessionKey

  _computeResponse: (request=@lastRequest) ->
    cipher = new JSUCrypt.cipher.DES(JSUCrypt.padder.None, JSUCrypt.cipher.MODE_CBC)
    key = new JSUCrypt.key.DESKey(@pairingKey)
    cipher.init(key, JSUCrypt.cipher.MODE_DECRYPT)
    data = cipher.update(request)
    h =
      pin: (String.fromCharCode(c) for c in data[0...4]).join('')
      outputAmount: parseInt (Convert.toHexByte(i) for i in data[4...12]).join('')
      fees: parseInt (Convert.toHexByte(i) for i in data[12...20]).join('')
      change: parseInt (Convert.toHexByte(i) for i in data[20...28]).join('')
      destination: (String.fromCharCode(c) for c in data[29...29+data[28]]).join('')
    l "%c[_computeResponse]", "color: #888888", h
    return h
