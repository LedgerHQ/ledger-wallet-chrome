class @Api

  @init: ->
    @_has_session = false
    ledger.app.on 'dongle:unlocked', ->
      Api._has_session = true
    ledger.app.on 'dongle:disconnected', ->
      Api._has_session = false

  @listener: (event) ->
    data = event.data
    switch data.command
      when 'has_session'
        @hasSession(data)
      when 'bitid'
        @bitid(data)
      when  'send_payment'
        @sendPayment(data)
      when 'sign_message'
        @signMessage(data)
      when 'sign_p2sh'
        @signP2SH(data)
      when 'get_xpubkey'
        @getXPubKey(data)
      when 'coinkite_get_xpubkey'
        @coinkiteGetXPubKey(data)
      when 'coinkite_sign_json'
        @coinkiteSignJSON(data)

  @hasSession: (data) ->
    chrome.runtime.sendMessage {
      command: 'has_session',
      success: Api._has_session
    }    

  @sendPayment: (data) ->
    ledger.app.router.go '/wallet/send/index', {address: data.address, amount: data.amount}

  @signMessage: (data) ->
    try
      ledger.app.wallet._lwCard.getBitIDAddress data.path
      .then (result) =>
        @address = result.bitcoinAddress.value
        ledger.app.wallet._lwCard.dongle.getMessageSignature(data.path, data.message)
        .then (result) =>
          @callback_success('sign_message', signature: result, address: @address)
          return
        .fail (error) =>
          @callback_cancel('sign_message', JSON.stringify(error))
          return
      .fail (error) =>
        @callback_cancel('sign_message', JSON.stringify(error))
        return
    catch error
      callback_cancel('sign_message', JSON.stringify(error))

  @signP2SH: (data) ->
    chrome.app.window.current().show()
    ledger.app.router.go '/wallet/p2sh/index', {inputs: JSON.stringify(data.inputs), scripts: JSON.stringify(data.scripts), outputs_number: data.outputs_number, outputs_script: data.outputs_script, paths: JSON.stringify(data.paths)}

  @getXPubKey: (data) ->
    chrome.app.window.current().show()
    ledger.app.router.go '/wallet/xpubkey/index', {path: data.path}

  @bitid: (data) ->
    chrome.app.window.current().show()
    ledger.app.router.go '/wallet/bitid/index', {uri: data.uri, silent: data.silent}

  @coinkiteGetXPubKey: (data) ->
    chrome.app.window.current().show()
    ledger.app.router.go '/apps/coinkite/keygen/index', {index: data.index}

  @coinkiteSignJSON: (data) ->
    chrome.app.window.current().show()
    ledger.app.router.go '/apps/coinkite/cosign/show', {json: JSON.stringify(data.json)}

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