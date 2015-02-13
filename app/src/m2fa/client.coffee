@ledger.m2fa ?= {}

# The mobile 2FA ChromeClient.
# client = new ledger.api.m2fa.Client(aPairingId)
# client.on 'm2fa.idendify', (data) ->
#   console.log data.public_key, "identified"
# client.requestValidation(tx)
class @ledger.m2fa.Client extends EventEmitter

  @BASE_URL: ledger.config.m2fa.baseUrl

  # @param [String] pairingId The id must be a valid btc address. Used to be a bitId address.
  constructor: (pairingId) ->
    @pairingId = pairingId
    @_joinRoom()

  isConnected: ->
    return @_connectionPromise && @_connectionPromise.isFullfilled()

  # Transmit 4 bytes challenge. 
  # @params [String] challenge is encoded in hex "8 nonce bytes"+"4 challenge bytes"
  sendChallenge: (challenge) ->
    @_send JSON.stringify(type: 'challenge', data: challenge)
    @emit 'm2fa.challenge.sended', challenge

  # End a pairing process whether its successful or not.
  confirmPairing: (success=true) ->
    @_send JSON.stringify(type: 'pairing', is_successful: success)
    @emit 'm2fa.pairing.confirmed', success
  rejectPairing: () ->
    @_send JSON.stringify(type: 'pairing', is_successful: false)
    @emit 'm2fa.pairing.rejected'

  requestValidation: (data) ->
    @_lastRequest = JSON.stringify(type: 'request', second_factor_data: data)
    @_send @_lastRequest
    @emit 'm2fa.request.sended', data

  _joinRoom: (pairingId) ->
    d = Q.defer()
    @_connectionPromise = d.promise
    @ws = new WebSocket(@constructor.BASE_URL)
    @ws.onopen = (e) =>
      @_onOpen(e)
      d.resolve()
    @ws.onmessage = _.bind(@_onMessage,@)
    @ws.onclose = _.bind(@_onClose,@)

  _leaveRoom: () ->
    @ws.send JSON.stringify(type: 'leave')
    @ws.close()
    @ws = null
    @_connectionPromise = null
    @emit 'm2fa.room.left'

  _onOpen: (e) ->
    @ws.send JSON.stringify(type: 'join', room: @pairingId)
    @ws.send JSON.stringify(type: 'repeat')
    @emit 'm2fa.room.joined'

  _onMessage: (e) ->
    data = JSON.parse(e.data)
    @emit 'm2fa.message', data
    switch data.type
      when "connect" then @_onConnect(data)
      when "disconnect" then @_onDisconnect(data)
      when "repeat" then @_onRepeat(data)
      when "accept" then @_onAccept(data)
      when "response" then @_onResponse(data)
      when "identify" then @_onIdentify(data)
      when "challenge" then @_onChallenge(data)

  _onClose: (e) ->
    @ws = null
    @_connectionPromise = null
    @_joinRoom()

  _send: (data) ->
    throw "Not connected" unless @ws?
    @_connectionPromise.then =>
      @ws.send(data)

  _onConnect: (data) ->
    @emit 'm2fa.connect'
  _onDisconnect: (data) ->
    @emit 'm2fa.disconnect'

  # Sent by mobile clients to request chrome application to repeat their 'request' message.
  _onRepeat: (data) ->
    @ws.send(@_lastRequest)

  # Sent by mobile clients to indicate the chrome application that one client is able to handle the 'request' message.
  _onAccept: (data) ->
    @emit 'm2fa.accept'

  # Sent by mobile clients to finalize the 'request' message.
  # If the 'request' message is accepted, the message must contain the "pin" parameter in order to validate the transaction.
  # @params [Object] data {"type": "response", "pin": "xxxxxxxxxxxx..."}
  _onResponse: (data) ->
    @emit 'm2fa.response', data.pin

  # Sent by mobile clients to transmit their generated public key.
  # @params [Object] data {"type": "identity", "public_key": "xxxxxxxxxxxx..."}
  _onIdentify: (data) ->
    @emit 'm2fa.identify', data.public_key

  # Sent by mobile apps to transmit their previously received challenge response.
  # Data is encoded in hex?
  # @params [Object] data {"type": "challenge", "data": "XxXxXxXx"}
  _onChallenge: (data) ->
    @emit 'm2fa.challenge', data.data
