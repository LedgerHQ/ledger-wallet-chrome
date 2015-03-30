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
      result: ledger.app.wallet? && (ledger.app.wallet._state is ledger.wallet.States.UNLOCKED) ? true : false
    }    

  @bitid: (data) ->
    @derivationPath = ledger.bitcoin.bitid.uriToDerivationPath(data.uri)
    ledger.app.router.go '/wallet/bitid/index', {uri: data.uri}
    ledger.app.wallet.signMessageWithBitId @derivationPath, data.uri, (result) ->
      chrome.runtime.sendMessage {
        command: 'bitid',
        address: ledger.app.wallet._lwCard.bitIdAddress[Api.derivationPath].bitcoinAddress.value,
        signature: result
      }
