class @Api

  @init: ->
    @_has_session = false
    ledger.app.on 'wallet:authenticated', ->
      Api._has_session = true

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
      result: Api._has_session
    }    

  @bitid: (data) ->
    @derivationPath = ledger.bitcoin.bitid.uriToDerivationPath(data.uri)
    ledger.app.router.go '/wallet/bitid/index', {uri: data.uri}