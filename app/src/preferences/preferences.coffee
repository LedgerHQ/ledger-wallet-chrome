ledger.preferences ?= {}

ledger.preferences.init = (cb) ->
  ledger.preferences.instance = new ledger.preferences.Preferences

  ledger.app.on 'wallet:initialized', () ->
    if ledger.storage.sync?
      obj = ledger.preferences.instance.prefs

      getAllPrefs = (keys, values, index = 0) ->
        return if index > keys.length - 1
        deferred = Q.defer()
        ledger.storage.sync.get 'preferences_' + keys[index], (res) ->
          ledger.preferences.instance.prefs[keys[index]] = res['preferences_' + keys[index]] ? values[index]
          deferred.resolve(getAllPrefs(keys, values, index + 1))
        deferred.promise

      getAllPrefs(_.keys(obj), _.values(obj)).then cb?().done()


class ledger.preferences.Preferences

  prefs:
    #language: undefined
    #locale: undefined
    btcUnit: 'BTC'
    currency: 'USD'
    miningFee: '10000'
    blockchainExplorator: 'https://blockchain.info/'

  ###
    Language
  ###
  getUILanguage: () ->
    ledger.i18n.favLang.memoryValue

  setUILanguage: (value) ->
    ledger.i18n.setFavLangByUI(value)


  ###
    Locale - Region preference for Date and currency formatting
  ###
  getUILocale: () ->
    ledger.i18n.favLocale.memoryValue

  setUILocale: (value) ->
    ledger.i18n.setLocale(value)


  ###
    BTC Unit
  ###
  getUIBtcUnit: () ->
    @prefs.btcUnit

  setUIBtcUnit: (value) ->
    @prefs.btcUnit = value
    if ledger.storage.sync?
      ledger.storage.sync.set({preferences_btcUnit: value})
    else
      throw new Error 'You must initialized your wallet'


  ###
    Fiat currency equivalent
  ###
  getUICurrency: () ->
    @prefs.currency

  setUICurrency: (value) ->
    @prefs.currency = value
    if ledger.storage.sync?
      ledger.storage.sync.set({preferences_currency: value})
    else
      throw new Error 'You must initialized your wallet'


  ###
    Mining Fee
  ###
  getUIMiningFee: () ->
    @prefs.miningFee

  setUIMiningFee: (value) ->
    @prefs.miningFee = value
    if ledger.storage.sync?
      ledger.storage.sync.set({preferences_miningFee: value})
    else
      throw new Error 'You must initialized your wallet'


  ###
    Blockchain explorator
  ###
  getUIBlockchainExplorator: () ->
    @prefs.blockchainExplorator

  setUIBlockchainExplorator: (value) ->
    @prefs.blockchainExplorator = value
    if ledger.storage.sync?
      ledger.storage.sync.set({preferences_blockchainExplorator: value})
    else
      throw new Error 'You must initialized your wallet'


window.onload = ledger.preferences.init
