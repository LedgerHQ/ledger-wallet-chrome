return unless @electron?


((@chrome ||= {}).runtime ||= {}).sendMessage = (extensionId, message, options, responseCallback) ->

chrome.runtime.getManifest = -> window.electron.require(__dirname + "/../manifest.json")

chrome.commands ||= {}
chrome.commands.onCommand ||= {}

_.extend chrome.commands.onCommand,
  addListener: ->

(chrome?.i18n ||= {}).getUILanguage = -> navigator.language
(chrome?.i18n ||= {}).getAcceptLanguages = (callback) -> callback? [navigator.language]
