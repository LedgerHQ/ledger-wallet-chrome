class @Api

  @listener: (event) ->
    data = event.data
    switch data.command
      when 'has_session'
        @has_session(data)
      when 'bitid'
        @bitid(data)

  @has_session: (data) ->
    chrome.runtime.sendMessage {
      command: 'has_session',
      result: ledger.app.wallet? ? true : false
    }

  @bitid: (data) ->
    console.log "BitID"
    console.log data
    uri = data.uri.replace("bitid://", "").replace("bitid:", "")
    uri = uri.substring(0, uri.indexOf("?"))
    derivationPath = "0'/0xb11e'/" + sha256_digest(uri).substring(0,8)
    ledger.app.wallet.getBitIdAddressWithDerivation derivationPath, (result) ->
      address = result
      ledger.app.wallet.signMessageWithBitId data.uri, (result) ->
        chrome.runtime.sendMessage {
          command: 'bitid',
          address: address,
          result: result
        }