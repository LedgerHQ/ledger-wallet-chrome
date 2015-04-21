ledger.preferences ?= {}

###
  Init - Get all preferences from Synced Store, fallback to default values
###
ledger.preferences.init = (cb) ->
  ledger.preferences.instance = new ledger.preferences.Preferences
  if ledger.storage.sync?
    obj = ledger.preferences.instance.prefs
    getAllPrefs = (keys, values, index = 0) ->
      return if index > keys.length - 1
      deferred = Q.defer()
      ledger.storage.sync.get '__preferences_' + keys[index], (res) ->
        ledger.preferences.instance.prefs[keys[index]] = res['__preferences_' + keys[index]] ? values[index]
        deferred.resolve(getAllPrefs(keys, values, index + 1))
      deferred.promise
    getAllPrefs(_.keys(obj), _.values(obj)).then(=> cb?()).done()


###
  Helpers to get/set preferences
###
class ledger.preferences.Preferences

  prefs:
    btcUnit: ledger.preferences.defaults.Display.units.bitcoin.symbol
    currency: 'USD'
    miningFee: ledger.preferences.defaults.Bitcoin.fees.normal.value
    blockchainExplorer: ledger.preferences.defaults.Bitcoin.explorers.blockchain.name
    currencyEquivalentIsActive: false
    logState: true
    confirmationsCount: ledger.preferences.defaults.Bitcoin.confirmations.one

  ###
    Get Language
    @example Get the current language
      ledger.preferences.instance.getLanguage()
  ###
  getLanguage: () ->
    ledger.i18n.favLang.memoryValue

  ###
    Set Language
    @param [String] value Codified (BCP 47) language tag - Official list here : http://www.iana.org/assignments/language-subtag-registry/language-subtag-registry
    @example Get the current language
      ledger.preferences.instance.setLanguage('es')
  ###
  setLanguage: (value) ->
    ledger.i18n.setFavLangByUI(value)


  # Get Locale - Region preference for Date and currency formatting
  getLocale: () ->
    ledger.i18n.favLocale.memoryValue

  ###
    Set Locale - Region preference for Date and currency formatting
    @param [String] value Codified (BCP 47) language tag - Official list here : http://www.iana.org/assignments/language-subtag-registry/language-subtag-registry
    @example Set user favorite localization
      ledger.preferences.instance.setLocale('en-GB')
  ###
  setLocale: (value) ->
    ledger.i18n.setLocaleByUI(value)


  # Get BTC Unit
  getBtcUnit: () ->
    @prefs.btcUnit

  # Set BTC Unit
  setBtcUnit: (value) ->
    if ledger.storage.sync?
      ledger.storage.sync.set({__preferences_btcUnit: value})
      @prefs.btcUnit = value
    else
      throw new Error 'You must initialize your wallet'


  # Get Fiat currency equivalent
  getCurrency: () ->
    @prefs.currency

  # Set Fiat currency equivalent
  setCurrency: (value) ->
    if ledger.storage.sync?
      ledger.storage.sync.set({__preferences_currency: value})
      @prefs.currency = value
    else
      throw new Error 'You must initialize your wallet'


  # Get state of fiat currency equivalent functionality - true/false
  getCurrencyActive: ->
    @prefs.currencyEquivalentIsActive

  # Set fiat currency equivalent functionality to active
  setCurrencyActive: (state = yes) ->
    if ledger.storage.sync?
      ledger.storage.sync.set({__preferences_currencyEquivalentIsActive: state})
      @prefs.currencyEquivalentIsActive = state
    else
      throw new Error 'You must initialize your wallet'

  # Get Mining Fee
  getMiningFee: () ->
    @prefs.miningFee

  # Set Mining Fee
  setMiningFee: (value) ->
    if ledger.storage.sync?
      ledger.storage.sync.set({__preferences_miningFee: value})
      @prefs.miningFee = value
    else
      throw new Error 'You must initialize your wallet'


  # Get Blockchain explorer
  getBlockchainExplorer: () ->
    @prefs.blockchainExplorer

  # Set Blockchain explorer
  setBlockchainExplorer: (value) ->
    if ledger.storage.sync?
      ledger.storage.sync.set({__preferences_blockchainExplorer: value})
      @prefs.blockchainExplorer = value
    else
      throw new Error 'You must initialize your wallet'

  # Get confirmations count
  getConfirmationsCount:  ->
    @prefs.confirmationsCount

  # Set confirmations count
  setConfirmationsCount: (value) ->
    if ledger.storage.sync?
      ledger.storage.sync.set({__preferences_confirmationsCount: value})
      @prefs.confirmationsCount = value
    else
      throw new Error 'You must initialize your wallet'

  ###
    If Logs must be visible todo
  ###
  getLogState: () ->
    @prefs.logState

  setLogState: (value) ->
    if typeof value is 'boolean'
      throw new Error 'Log state must be a boolean'
    @prefs.logState = value

  getAllBitcoinUnits: ->
    _.map(_.values(ledger.preferences.defaults.Display.units), (unit) -> unit.symbol)