@ledger.m2fa ?= {}

DebugWebsocket = (message) -> l message


# The mobile 2FA ChromeClient.
# client = new ledger.api.m2fa.Client(aPairingId)
# client.on 'm2fa.idendify', (data) ->
#   console.log data.public_key, "identified"
# client.requestValidation(tx)
class @ledger.m2fa.Client extends ledger.tasks.Task

  @BASE_URL: ledger.config.m2fa.baseUrl

  # @param [String] pairingId The id must be a valid btc address. Used to be a bitId address.
  constructor: (pairingId) ->
    super(pairingId)
    @start()
    @pairingId = pairingId
    @_joinRoom()

  isConnected: ->
    return @_connectionPromise && @_connectionPromise.isFullfilled()

  # Sets the name of the dongle asynchronously. Default is ""
  pairedDongleName: new CompletionClosure().success("")

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

  # Redefine from Task
  onStop: () ->
    ledger.m2fa.clients = _.omit(ledger.m2fa.clients, @pairingId)
    @_leaveRoom()

  _joinRoom: (pairingId) ->
    return @_connectionPromise if @_connectionPromise?
    d = Q.defer()
    @_connectionPromise = d.promise
    @ws = new WebSocket(@constructor.BASE_URL)
    if DebugWebsocket?
      do (@ws) ->
        ws._send = ws.send
        ws.send = (data) ->
          DebugWebsocket?("[WS] ==> " + data)
          ws._send(data)
    @ws.onopen = (e) =>
      @_onOpen(e)
      d.resolve()
    @ws.onmessage = _.bind(@_onMessage,@)
    @ws.onclose = _.bind(@_onClose,@)
    @_connectionPromise

  _leaveRoom: () ->
    return unless @ws?
    [ws, @ws, @_connectionPromise] = [@ws, undefined, undefined]
    ws.onclose = undefined
    ws.send JSON.stringify(type: 'leave') if ws.readyState == WebSocket.OPEN
    ws.close()
    @emit 'm2fa.room.left'

  _onOpen: (e) ->
    DebugWebsocket?("[WS] Open")
    @ws.send JSON.stringify(type: 'join', room: @pairingId)
    @ws.send JSON.stringify(type: 'repeat')
    @emit 'm2fa.room.joined'

  _onMessage: (e) ->
    DebugWebsocket?("[WS] <== #{e.data}")
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
    DebugWebsocket?("[WS] Close")
    [@ws.onclose, @ws.onmessage] = [undefined, undefined]
    [@ws, @_connectionPromise] = [undefined, undefined]
    @_joinRoom()

  _send: (data) ->
    @_joinRoom().then(=> @_send(data)) if ! @_connectionPromise?
    @_connectionPromise.then =>
      @ws.send(data)

  _onConnect: (data) ->
    @emit 'm2fa.connect'

  _onDisconnect: (data) ->
    @emit 'm2fa.disconnect'

  # Sent by mobile clients to request chrome application to repeat their 'request' message.
  _onRepeat: (data) ->
    @ws.send(@_lastRequest) if @_lastRequest?

  # Sent by mobile clients to indicate the chrome application that one client is able to handle the 'request' message.
  _onAccept: (data) ->
    @emit 'm2fa.accept'

  # Sent by mobile clients to finalize the 'request' message.
  # If the 'request' message is accepted, the message must contain the "pin" parameter in order to validate the transaction.
  # @params [Object] data {"type": "response", "pin": "xxxxxxxxxxxx..."}
  _onResponse: (data) ->
    if data.is_accepted
      @emit 'm2fa.response', data.pin
    else
      @emit 'm2fa.reject'

  # Sent by mobile clients to transmit their generated public key.
  # @params [Object] data {"type": "identity", "public_key": "xxxxxxxxxxxx..."}
  _onIdentify: (data) ->
    @lastIdentifyData = data
    @emit 'm2fa.identify', data.public_key

  # Sent by mobile apps to transmit their previously received challenge response.
  # Data is encoded in hex?
  # @params [Object] data {"type": "challenge", "data": "XxXxXxXx"}
  _onChallenge: (data) ->
    @emit 'm2fa.challenge', data.data
