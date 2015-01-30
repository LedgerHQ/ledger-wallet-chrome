# M2FA, for Mobile 2 Factor Authentification, allow you to pair a mobile device,
# and then securely ask for user validation of the transaction.
@ledger.m2fa ?= {}
_.extend @ledger.m2fa,
  
  clients: {}

  # This method :
  # - create a new pairingId ;
  # - connect to the corresponding room on server ;
  # - wait for mobile pubKey ;
  # - send challenge to mobile ;
  # - wait for challenge response ;
  # - verify response ;
  # - notity mobile of the pairing success/failure.
  #
  # The return promise :
  # - notify when "pubKeyReceived" ;
  # - notify when "challengeReceived" ;
  # - resolve if dongle confirm pairing.
  # - reject one any fail.
  #
  # @return [pairingId, aPromise]
  pairDevice: () ->
    d = Q.defer()
    pairingId = @_nextPairingId()
    client = new ledger.m2fa.Client(pairingId)
    @clients[pairingId] = client    
    client.on 'm2fa.identify', (pubKey) => @_onIdentify(client, pubKey, d)
    client.on 'm2fa.challenge', (data) => @_onChallenge(client, data, d)
    return [pairingId, d.promise]

  # Allow you to assign a label to a pairingId (ex: "mobile Pierre").
  # @params [String] pairingId
  # @params [String] label
  setPairingLabel: (pairingId, label) ->
    h = {}
    h["__m2fa_#{pairingId}"] = label
    ledger.storage.sync.set(h)

  # @return Promise an object where each key is pairingId and the value the associated label.
  getPairingIds: () ->
    d = Q.defer()
    ledger.storage.sync.keys (keys) ->
      keys = _.filter(keys, (key) -> key.match(/^__m2fa_/))
      ledger.storage.sync.get keys, (items) ->
        pairingCuple = {}
        for key, value of items
          pairingCuple[key.replace(/^__m2fa_/,'')] = value
        d.resolve(pairingCuple)
    d.promise

  # Validate with M2FA that tx is correct.
  # @param [String] tx
  # @param [String] challenge
  # @param [String] pairingId The paired mobile to send validation.
  # @return A Q promise.
  validateTx: (tx, challenge, pairingId) ->
    d = Q.defer()
    client = @_getClientFor(pairingId)
    client.off 'm2fa.accept'
    client.off 'm2fa.response'
    client.on 'm2fa.accept', ->
      d.notify('accepted')
    client.on 'm2fa.response', (blob) ->
      client.off 'm2fa.accept'
      client.off 'm2fa.response'
      d.resolve(blob)
    client.requestValidation(tx: tx, challenge: challenge)
    d.promise

  # Validate with M2FA that tx is correct on every paired mobile.
  # @param [String] tx
  # @param [String] challenge
  # @param [String] pairingId The paired mobile to send validation.
  # @return A Q promise.
  validateTxOnAll: (tx, challenge) ->
    d = Q.defer()
    @getPairingIds().then (pairingIds) =>
      for pairingId, label of pairingIds
        @validateTx(tx, challenge, pairingId)
        .progress (p) -> d.notify(p)
        .then (blob) -> d.resolve(blob)
    d.promise

  _nextPairingId: () -> 
    # ledger.wallet.safe.randomBitIdAddress()
    @_randomPairingId()

  # @return a random 16 bytes pairingId + 1 checksum byte hex encoded.
  _randomPairingId: () ->
    words = sjcl.random.randomWords(4)
    hexaWords = (Convert.toHexInt(w) for w in words).join('')
    hash = sjcl.hash.sha256.hash(words)
    pairingId = hexaWords + Convert.toHexByte(hash[0] >>> 24)

  _getClientFor: (pairingId) ->
    @clients[pairingId] ||= new ledger.m2fa.Client(pairingId)

  _onIdentify: (client, pubKey, d) ->
    d.notify("pubKeyReceived")
    try
      ledger.wallet.safe().initiateSecureScreen(pubKey).catch(_.bind(d.reject,d)).then (challenge) ->
        client.sendChallenge(challenge)
    catch e
      d.reject(e)

  _onChallenge: (client, data, d) ->
    d.notify("challengeReceived")
    try
      ledger.wallet.safe().confirmSecureScreen(data).catch( ->
        client.rejectPairing()
        d.reject()
      ).then ->
        client.confirmPairing()
        d.resolve()
    catch e
      d.reject(e)

