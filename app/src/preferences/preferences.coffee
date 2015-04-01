ledger.preferences ?= {}

ledger.preferences.init = (cb) ->
  ledger.preferences.instance = new ledger.preferences.Preferences
  if ledger.storage.sync?
    obj = ledger.preferences.instance.prefs
    getAllPrefs = (keys, values, index = 0) ->
      return if index > keys.length - 1
      deferred = Q.defer()
      ledger.storage.sync.get 'preferences_' + keys[index], (res) ->
        ledger.preferences.instance.prefs[keys[index]] = res['preferences_' + keys[index]] ? values[index]
        deferred.resolve(getAllPrefs(keys, values, index + 1))
      deferred.promise
    getAllPrefs(_.keys(obj), _.values(obj)).then(=> cb?()).done()


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
    ledger.i18n.setLocaleByUI(value)


  ###
    BTC Unit
  ###
  getUIBtcUnit: () ->
    @prefs.btcUnit

  setUIBtcUnit: (value) ->
    if value isnt 'BTC' and value isnt 'mBTC' and value isnt 'uBTC' and value isnt 'satoshi'
      try
        throw new Error("'BtcUnit' must be BTC, mBTC, uBTC or satoshi")
      catch e
        console.log(e.name + ": " + e.message)
        return null
    if ledger.storage.sync?
      ledger.storage.sync.set({preferences_btcUnit: value})
      @prefs.btcUnit = value
    else
      throw new Error 'You must initialized your wallet'


  ###
    Fiat currency equivalent
  ###
  getUICurrency: () ->
    @prefs.currency

  setUICurrency: (value) ->
    if ledger.storage.sync?
      ledger.storage.sync.set({preferences_currency: value})
      @prefs.currency = value
    else
      throw new Error 'You must initialized your wallet'


  ###
    Mining Fee
  ###
  getUIMiningFee: () ->
    @prefs.miningFee

  setUIMiningFee: (value) ->
    if ledger.storage.sync?
      ledger.storage.sync.set({preferences_miningFee: value})
      @prefs.miningFee = value
    else
      throw new Error 'You must initialized your wallet'


  ###
    Blockchain explorator
  ###
  getUIBlockchainExplorator: () ->
    @prefs.blockchainExplorator

  setUIBlockchainExplorator: (value) ->
    if ledger.storage.sync?
      ledger.storage.sync.set({preferences_blockchainExplorator: value})
      @prefs.blockchainExplorator = value
    else
      throw new Error 'You must initialized your wallet'