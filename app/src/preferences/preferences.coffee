ledger.preferences ?= {}

###
  Init - Get all preferences from Synced Store, fallback to default values
###
ledger.preferences.init = (cb) ->
  ledger.preferences.instance = new ledger.preferences.Preferences
  ledger.preferences.instance.init(cb)

ledger.preferences.close = ->
  ledger.preferences.instance?.close()
  ledger.preferences.instance = undefined

PreferencesStructure =
  btcUnit:
    default: ledger.preferences.defaults.Display.units.bitcoin.symbol
    synchronized: yes

  currency:
    default: 'USD'

  miningFee:
    default: ledger.preferences.defaults.Bitcoin.fees.normal.value

  blockchainExplorer:
    default: _.keys(ledger.preferences.defaults.Bitcoin.explorers)[0]

  currencyActive:
    default: true

  logActive:
    default: true

  confirmationsCount:
    default: ledger.preferences.defaults.Bitcoin.confirmations.one

  language:
    getter: -> ledger.i18n.favLang.memoryValue
    setter: ledger.i18n.setFavLangByUI.bind(ledger.i18n)

  locale:
    getter: -> ledger.i18n.favLocale.memoryValue
    setter: ledger.i18n.setLocaleByUI.bind(ledger.i18n)

###
  Helpers to get/set preferences
###
class ledger.preferences.Preferences extends EventEmitter

  constructor: ->
    @_preferences = _.clone PreferencesStructure
    defaultGetter = -> @_value
    defaultSetter = (value) ->
      @_value = value
      save = {}
      save[@storeKey] = value
      ledger.storage.sync.set?(save)

    for prefId, preference of @_preferences
      preference.storeKey = @_prefIdToStoreKey(prefId)
      preference.getter = defaultGetter.bind(preference) unless preference.getter?
      preference.setter = defaultSetter.bind(preference) unless preference.setter?
    ledger.storage.sync.on 'pulled', => @_updatePreferences(on, _.noop)

  init: (callback) -> @_updatePreferences(off, callback)

  close: () ->
    @off()

  getLanguage: -> @_getPreference('language')
  setLanguage: (value) -> @_setPreference('language', value)

  getLocale: -> @_getPreference('locale')
  setLocale: (value) -> @_setPreference('locale', value)

  getBtcUnit: -> @_getPreference('btcUnit')
  setBtcUnit: (value) -> @_setPreference('btcUnit', value)

  getCurrency: -> @_getPreference('currency')
  setCurrency: (value) -> @_setPreference('currency', value)

  isCurrencyActive: -> @_getPreference('currencyActive')
  setCurrencyActive: (value) -> @_setPreference('currencyActive', value)

  getMiningFee: -> @_getPreference('miningFee')
  setMiningFee: (value) -> @_setPreference('miningFee', value)

  getBlockchainExplorer: -> @_getPreference('blockchainExplorer')
  setBlockchainExplorer: (value) -> @_setPreference('blockchainExplorer', value)

  getConfirmationsCount:  -> @_getPreference 'confirmationsCount'
  setConfirmationsCount: (value) -> @_setPreference 'confirmationsCount', value

  ###
    Gets and Sets logging state
  ###
  isLogActive: -> @_getPreference 'logActive'
  setLogActive: (value) -> @_setPreference 'logActive', value

  getAllBitcoinUnits: -> _.map(_.values(ledger.preferences.defaults.Display.units), (unit) -> unit.symbol)
  getBitcoinUnitMaximumDecimalDigitsCount: () -> _.object.apply(_, _.unzip(_.map(ledger.preferences.defaults.Display.units, (u) -> [u.symbol, u.unit])))[@getBtcUnit()]
  getBlockchainExplorerAddress: -> ledger.preferences.defaults.Bitcoin.explorers[@getBlockchainExplorer()].address

  isConfirmationCountReached: (count) -> count >= @getConfirmationsCount()

  _setPreference: (prefId, value, emit = yes) ->
    preference = @_preferences[prefId]
    throw new Error("Preference #{prefId} does not exist") unless preference?
    oldValue = preference.getter()
    preference.setter(value)
    @emit "#{prefId}:changed", oldValue: oldValue, newValue: preference.getter() if emit and oldValue != value

  _getPreference: (prefId) ->
    preference = @_preferences[prefId]
    throw new Error("Preference #{prefId} does not exist") unless preference?
    value = preference.getter()
    if value? then value else preference.default

  _prefIdToStoreKey: (prefId) -> "__preferences_#{prefId}"
  _storeKeyToPrefId: (storeKey) -> storeKey.substr(14)

  _updatePreferences: (emit, callback) ->
    storeKeys = _.map _.keys(@_preferences), (prefId) => @_prefIdToStoreKey(prefId)
    ledger.storage.sync.get storeKeys, (storeValues) =>
      for storeKey, value of storeValues
        prefId = @_storeKeyToPrefId(storeKey)
        @_setPreference prefId, value
      callback?()