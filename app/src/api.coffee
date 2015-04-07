class @Api

  @init: ->
    @_has_session = false
    ledger.app.on 'dongle:unlocked', ->
      Api._has_session = true

  @listener: (event) ->
    data = event.data
    switch data.command
      when 'has_session'
        @hasSession(data)
      when 'bitid'
        @bitid(data)
      when  'send_payment'
        @sendPayment(data)

  @hasSession: (data) ->
    chrome.runtime.sendMessage {
      command: 'has_session',
      success: @_has_session
    }    

  @sendPayment: (data) ->
    console.log "sendPayment"
    ledger.app.router.go '/wallet/send/index', {address: data.address, amount: data.amount}

  @bitid: (data) ->
    ledger.app.router.go '/wallet/bitid/index', {uri: data.uri, silent: data.silent}

  @callback_cancel: (command, message) ->
    chrome.runtime.sendMessage 
      command: command,
      success: false,
      message: message

  @callback_success: (command, data) ->
    chrome.runtime.sendMessage $.extend {
        command: command,
        success: true 
      }, data