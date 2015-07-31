ledger.managers ?= {}

class ledger.managers.Application extends EventEmitter

  stringVersion: -> ledger.runtime.getManifest().version

  fullStringVersion: ->
    return t('application.name') + ' Chrome ' + @stringVersion()

ledger.managers.application = new ledger.managers.Application()

unless chrome?.runtime?.getManifest?
  ((@chrome ||= {}).runtime ||= {}).getManifest = ->
    chrome.runtime.getManifest._manifest = global.require '../manifest.json'

(ledger.runtime ||= {}).getManifest = ->
  chrome.runtime.getManifest._manifest ||= if global?.require? then global.require '../manifest.json' else chrome.runtime.getManifest()