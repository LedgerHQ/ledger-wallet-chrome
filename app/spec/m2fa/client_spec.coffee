describe "m2fa.Client", ->

  beforeEach ->
    spyOn(window, 'WebSocket')
    @pairingId = "aPairingId"
    @client = new ledger.m2fa.Client(@pairingId)
    @client.ws = @ws = jasmine.createSpyObj('ws', ['send', 'close'])
    [@ws.onopen, @ws.onmessage, @ws.onclose] = [ws.onopen, ws.onmessage, ws.onclose]
    spyOn(@client, "_send").and.callThrough()
    @ws.readyState = WebSocket.OPEN

  afterEach ->
    @client.stop()
  
  it "connect to 2fa on creation and set event callbacks", ->
    expect(window.WebSocket).toHaveBeenCalledWith(ledger.config.m2fa.baseUrl)
    expect(@ws.onopen).toBeDefined()
    expect(@ws.onmessage).toBeDefined()
    expect(@ws.onclose).toBeDefined()

  it "send challenge send good stringified message", ->
    challenge = "XxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXx"
    @client.sendChallenge(challenge)
    expect(@client._send).toHaveBeenCalledWith(JSON.stringify(type:"challenge","data":challenge))

  it "confirm pairing send good stringified message", ->
    @client.confirmPairing()
    expect(@client._send).toHaveBeenCalledWith(JSON.stringify(type:'pairing', is_successful:true))

  it "reject pairing send good stringified message", ->
    @client.rejectPairing()
    expect(@client._send).toHaveBeenCalledWith(JSON.stringify(type:'pairing', is_successful:false))

  it "request validation send good stringified message", ->
    data = "11XxXxXxXxXxXx88XxXxXxXxXxXxXxFF"
    @client.requestValidation(data)
    expect(@client._send).toHaveBeenCalledWith(JSON.stringify(type:'request', second_factor_data:data))

  it "leave room send message and close connection", ->
    @client._leaveRoom()
    expect(@ws.send).toHaveBeenCalledWith(JSON.stringify(type:'leave'))
    expect(@ws.close).toHaveBeenCalled()

  it "join correct room on connection", ->
    @client._onOpen()
    expect(@ws.send).toHaveBeenCalledWith(JSON.stringify(type:'join', room: @pairingId))
  
  it "parse message and call correct handler on message", ->
    message = {data: '{"type":"challenge","data":"0x1x2x3x"}'}
    spyOn(@client, '_onChallenge')
    @client._onMessage(message)
    expect(@client._onChallenge).toHaveBeenCalledWith({"type":"challenge","data":"0x1x2x3x"})

    spyOn(@client, '_onConnect')
    message = {data: '{"type":"connect"}'}
    @client._onMessage(message)
    expect(@client._onConnect).toHaveBeenCalled()    

  it "rejoin correct room on connection closed", ->
    spyOn(@client, '_joinRoom')
    @client._onClose()
    expect(@client._joinRoom).toHaveBeenCalled()

  it "emit event on most messages", ->
    spyOn(@client, 'emit')

    @client._onConnect({})
    expect(@client.emit).toHaveBeenCalledWith('m2fa.connect')
    @client.emit.calls.reset()

    @client._onDisconnect({})
    expect(@client.emit).toHaveBeenCalledWith('m2fa.disconnect')
    @client.emit.calls.reset()

    @client._onAccept({})
    expect(@client.emit).toHaveBeenCalledWith('m2fa.accept')
    @client.emit.calls.reset()

    @client._onResponse({pin: "01020304", is_accepted: true})
    expect(@client.emit).toHaveBeenCalledWith('m2fa.response', "01020304")
    @client.emit.calls.reset()
    
    @client._onIdentify({public_key: "toto"})
    expect(@client.emit).toHaveBeenCalledWith('m2fa.identify', "toto")
    @client.emit.calls.reset()
    
    @client._onChallenge({"data":"data"})
    expect(@client.emit).toHaveBeenCalledWith('m2fa.challenge', "data")
    @client.emit.calls.reset()

  it "resend last request on repeat", ->
    @client._lastRequest = '{"type":"challenge","data":"0x1x2x3x"}'
    @client._onRepeat()
    expect(@ws.send).toHaveBeenCalledWith('{"type":"challenge","data":"0x1x2x3x"}')
