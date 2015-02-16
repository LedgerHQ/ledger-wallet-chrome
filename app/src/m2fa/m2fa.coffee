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
    client = @_clientFactory(pairingId)
    @clients[pairingId] = client    
    client.on 'm2fa.identify', (e,pubKey) => @_onIdentify(client, pubKey, d)
    client.on 'm2fa.challenge', (e,data) => @_onChallenge(client, data, d)
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
      try
        keys = _.filter(keys, (key) -> key.match(/^__m2fa_/))
        ledger.storage.sync.get keys, (items) ->
          try
            pairingCuple = {}
            for key, value of items
              pairingCuple[key.replace(/^__m2fa_/,'')] = value
            d.resolve(pairingCuple)
          catch err
            d.reject(err)
      catch err
        d.reject(err)
    d.promise

  # Validate with M2FA that tx is correct.
  # @param [Object] tx A ledger.wallet.Transaction
  # @param [String] pairingId The paired mobile to send validation.
  # @return A Q promise.
  validateTx: (tx, pairingId) ->
    d = Q.defer()
    client = @_getClientFor(pairingId)
    client.off 'm2fa.accept'
    client.off 'm2fa.response'
    client.on 'm2fa.accept', ->
      d.notify('accepted')
    client.on 'm2fa.response', (e,pin) ->
      client.off 'm2fa.accept'
      client.off 'm2fa.response'
      l "%c[M2FA][#{pairingId}] request's pin received :", "#888888", pin
      tx.validate pin, (transaction, error) =>
        if error?
          l "%c[M2FA][#{pairingId}] tx validation FAILED :", "#CC0000", error
          d.reject(error)
        else
          l "%c[M2FA][#{pairingId}] tx validation SUCCEEDED", "#00CC00"
          d.resolve(transaction)
    client.requestValidation(tx._out.authorizationPaired)
    d.promise

  # Validate with M2FA that tx is correct on every paired mobile.
  # @param [Object] tx A ledger.wallet.Transaction
  # @param [String] pairingId The paired mobile to send validation.
  # @return A Q promise.
  validateTxOnAll: (tx) ->
    d = Q.defer()
    @getPairingIds().then (pairingIds) =>
      for pairingId, label of pairingIds
        @validateTx(tx, pairingId)
        .progress (p) -> d.notify(p)
        .then (transaction) -> d.resolve(transaction)
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
    @clients[pairingId] ||= @_clientFactory(pairingId)

  _onIdentify: (client, pubKey, d) ->
    d.notify("pubKeyReceived", pubKey)
    l("%c[_onIdentify] pubKeyReceived", "color: #4444cc", pubKey)
    try
      ledger.wallet.safe().initiateSecureScreen(pubKey).then((challenge) ->
        l("%c[_onIdentify] challenge received:", "color: #4444cc", challenge)
        client.sendChallenge(challenge)
      ).fail( (err) =>
        e(err)
        d.reject()
      ).done()
    catch err
      e(err)
      d.reject(err)

  _onChallenge: (client, data, d) ->
    d.notify("challengeReceived")
    l("%c[_onChallenge] challengeReceived", "color: #4444cc", data)
    try
      ledger.wallet.safe().confirmSecureScreen(data).then( =>
        l("%c[_onChallenge] SUCCESS !!!", "color: #00ff00" )
        client.confirmPairing()
        @setPairingLabel(client.pairingId, "")
        d.resolve()
      ).fail( (e) =>
        l("%c[_onChallenge] >>>  FAILURE  <<<", "color: #ff0000", e)
        client.rejectPairing()
        d.reject()
      ).done()
    catch err
      e(err)
      d.reject(err)

  _clientFactory: (pairingId) ->
    new ledger.m2fa.Client(pairingId)
    #new ledger.m2fa.DebugClient(pairingId)
