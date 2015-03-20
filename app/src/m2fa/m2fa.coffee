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
  # - notify mobile of the pairing success/failure.
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
    client.on 'm2fa.disconnect', (e, data) => @_onDisconnect(client, data, d)
    [pairingId, d.promise, client]

  # Creates a new pairing request and starts the m2fa pairing process.
  # @see ledger.m2fa.PairingRequest
  # @return [ledger.m2fa.PairingRequest] The request interface
  requestPairing: () ->
    [pairingId, promise, client] = @pairDevice()
    new ledger.m2fa.PairingRequest(pairingId, promise, client)

  # Allow you to assign a label to a pairingId (ex: "mobile Pierre").
  # @params [String] pairingId
  # @params [String] label
  saveSecureScreen: (pairingId, screenData) ->
    data =
      name: screenData['name']
      platform: screenData['platform']
      uuid: screenData['uuid']
    ledger.m2fa.PairedSecureScreen.create(pairingId, data).toSyncedStore()

  # @return Promise an object where each key is pairingId and the value the associated label.
  getPairingIds: () ->
    d = Q.defer()
    ledger.storage.sync.keys (keys) ->
      try
        keys = _.filter(keys, (key) -> key.match(/^__m2fa_/))
        ledger.storage.sync.get keys, (items) ->
          pairingCuple = {}
          for key, value of items
            pairingCuple[key.replace(/^__m2fa_/,'')] = value
          d.resolve(pairingCuple)
      catch err
        d.reject(err)
    d.promise

  # Validate with M2FA that tx is correct.
  # @param [Object] tx A ledger.wallet.Transaction
  # @param [String] pairingId The paired mobile to send validation.
  # @return A Q promise.
  validateTx: (tx, pairingId) ->
    ledger.api.M2faRestClient.instance.wakeUpSecureScreens([pairingId])
    @_validateTx(tx, pairingId)

  _validateTx: (tx, pairingId) ->
    d = Q.defer()
    client = @_getClientFor(pairingId)
    client.off 'm2fa.accept'
    client.off 'm2fa.response'
    client.on 'm2fa.accept', ->
      d.notify('accepted')
      client.off 'm2fa.accept'
    client.once 'm2fa.disconnect', ->
      d.notify('disconnected')
    client.on 'm2fa.response', (e,pin) ->
      l "%c[M2FA][#{pairingId}] request's pin received :", "#888888", pin
      client.stopIfNeccessary()
      d.resolve(pin)
    client.once 'm2fa.reject', ->
      client.stopIfNeccessary()
      d.reject('cancelled')
    client.requestValidation(tx._out.authorizationPaired)
    [client , d.promise]

  # Validate with M2FA that tx is correct on every paired mobile.
  # @param [Object] tx A ledger.wallet.Transaction
  # @param [String] pairingId The paired mobile to send validation.
  # @return A Q promise.
  validateTxOnAll: (tx) ->
    d = Q.defer()
    clients = []
    @getPairingIds().then (pairingIds) =>
      ledger.api.M2faRestClient.instance.wakeUpSecureScreens(_.keys(pairingIds))
      for pairingId, label of pairingIds
        do (pairingId) =>
          [client, promise] = @_validateTx(tx, pairingId)
          clients.push client
          promise.progress (msg) ->
            if msg == 'accepted'
              # Close all other client
              @clients[pId].stopIfNeccessary() for pId, lbl of pairingIds when pId isnt pairingId
            d.notify(msg)
          .then (transaction) -> d.resolve(transaction)
          .fail (er) -> d.reject er
          .done()
    .fail (er) ->
      e er
      throw er
    [clients, d.promise]

  validateTxOnMultipleIds: (tx, pairingIds) ->
    d = Q.defer()
    clients = []
    ledger.api.M2faRestClient.instance.wakeUpSecureScreens(pairingIds)
    for pairingId in pairingIds
      do (pairingId) =>
        [client, promise] = @_validateTx(tx, pairingId)
        clients.push client
        promise.progress (msg) =>
          if msg == 'accepted'
            # Close all other client
            @clients[pId].stopIfNeccessary() for pId in pairingIds when pId isnt pairingId
          d.notify(msg)
        .then (transaction) -> d.resolve(transaction)
        .fail (er) -> d.reject er
        .done()
    [clients, d.promise]

  # Creates a transaction validation request and starts the validation process.
  # @see ledger.m2fa.TransactionValidationRequest
  # @return [ledger.m2fa.TransactionValidationRequest] The request interface
  requestValidationOnAll: (tx) ->
    [clients, promise] = @validateTxOnAll(tx)
    new ledger.m2fa.TransactionValidationRequest(clients, promise)

  requestValidation: (tx, screen) ->
    unless _(screen).isArray()
      [client, promise] = @validateTx(tx, screen.id)
      new ledger.m2fa.TransactionValidationRequest([client], promise, tx, screen)
    else
      [clients, promise] = @validateTxOnMultipleIds(tx, _(screen).map (e) -> e.id)
      new ledger.m2fa.TransactionValidationRequest(clients, promise)

  requestValidationForLastPairing: (tx) ->
    [client, promise] = @validateTx(tx)

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
        d.notify("sendChallenge", challenge)
        client.sendChallenge(challenge)
      ).fail( (err) =>
        e(err)
        d.reject('initiateFailure')
        client.stopIfNeccessary()
      ).done()
    catch err
      e(err)
      d.reject(err)
      client.stopIfNeccessary()

  _onChallenge: (client, data, d) ->
    screenData = _.clone(client.lastIdentifyData)
    d.notify("challengeReceived")
    l("%c[_onChallenge] challengeReceived", "color: #4444cc", data)
    try
      ledger.wallet.safe().confirmSecureScreen(data).then( =>
        l("%c[_onChallenge] SUCCESS !!!", "color: #00ff00", data )
        client.confirmPairing()
        d.notify("secureScreenConfirmed")
        client.pairedDongleName.onComplete (name, err) =>
          return d.reject('cancel') if err?
          screenData['name'] = name
          d.resolve @saveSecureScreen(client.pairingId, screenData)
      ).fail( (e) =>
        l("%c[_onChallenge] >>>  FAILURE  <<<", "color: #ff0000", e)
        client.rejectPairing()
        d.reject('invalidChallenge')
      ).finally(=>
        client.stopIfNeccessary()
      ).done()
    catch err
      e(err)
      d.reject(err)
      client.stopIfNeccessary()

  _onDisconnect: (client, data, d) ->
    d.notify "secureScreenDisconnect"

  _clientFactory: (pairingId) ->
    new ledger.m2fa.Client(pairingId)
    #new ledger.m2fa.DebugClient(pairingId)
