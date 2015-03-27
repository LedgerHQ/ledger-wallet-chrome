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
      result: @_state is ledger.wallet.States.UNLOCKED ? true : false
    }

  @bitid: (data) ->
    console.log "BitID"
    console.log data
    uri = data.uri.replace("bitid://", "").replace("bitid:", "")
    uri = uri.substring(0, uri.indexOf("?"))
    derivationPath = "0'/0xb11e'/0x" + sha256_digest(uri).substring(0,8)
    ledger.app.router.go '/wallet/bitid/index'
    ledger.app.wallet.signMessageWithBitId derivationPath, data.uri, (result) ->
      chrome.runtime.sendMessage {
        command: 'bitid',
        address: ledger.app.wallet._lwCard.bitIdAddress.bitcoinAddress.value,
        signature: result
      }