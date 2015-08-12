ledger.managers ?= {}

class ledger.managers.Application extends EventEmitter

  stringVersion: ->
    return chrome.runtime.getManifest().version

  fullStringVersion: ->
    return t('application.name') + ' Chrome ' + @stringVersion()

ledger.managers.application = new ledger.managers.Application()