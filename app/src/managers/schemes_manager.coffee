ledger.managers ?= {}
ledger.managers.schemes ?= {}

class ledger.managers.schemes.Base extends EventEmitter

  parseURI: (uri) ->
    undefined

class ledger.managers.schemes.Bitcoin extends ledger.managers.schemes.Base

  parseURI: (uri) ->
    return undefined unless uri?
    uri = ledger.url.parseAsUrl uri
    return undefined unless (uri? and uri.protocol == 'bitcoin:' and uri.pathname? and uri.pathname.length > 0)
    hash = {}
    params = uri.params()
    hash.address = uri.pathname
    hash.amount = params.amount if params.amount? and params.amount.length > 0
    return hash

ledger.managers.schemes.bitcoin = new ledger.managers.schemes.Bitcoin()