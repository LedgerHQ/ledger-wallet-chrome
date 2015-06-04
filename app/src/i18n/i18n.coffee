###
  Internationalization and Localization
###
class ledger.i18n

  # chromeStore instance
  @chromeStore: undefined
  # Contain all the translation files
  @translations: {}

  ###
    User Favorite Language object

    @favLang
      memoryValue [String] The user favorite language in memory
      syncStoreValue [String] The user favorite language into syncStore
      chromeStoreValue [String] The user favorite language into chromeStore
      syncStoreIsSet [Boolean] If @favLang.syncStoreValue is set into syncStore
      chromeStoreIsSet [Boolean] If @favLang.chromeStoreValue is set into chromeStore
  ###
  @favLang:
    memoryValue: undefined
    syncStoreValue: undefined
    chromeStoreValue: undefined
    syncStoreIsSet: undefined
    chromeStoreIsSet: undefined
    storesAreSync: undefined

  ###
    User favorite language and region (Locale)
  ###
  @favLocale:
    memoryValue: undefined
    syncStoreValue: undefined
    chromeStoreValue: undefined
    syncStoreIsSet: undefined
    chromeStoreIsSet: undefined
    storesAreSync: undefined


  # Languages + regions tags that represent the user's Chrome browser preferences
  @browserAcceptLanguages: undefined
  # Supported languages by the app (when translation is done)
  @Languages: {}


  @init: (cb) =>
    @chromeStore = new ledger.storage.ChromeStore('i18n')

    @loadTranslationFiles()
    .then => @initBrowserAcceptLanguages()
    .then => Q.all([@initStoreValues('favLang'), @initStoreValues('favLocale')])
    .then => @setMomentLocale() # set locale for Moment.js
    .catch (err) -> l err
    .then => cb()
    .catch (err) -> l err
    .done()

    ledger.app.on 'wallet:initialized', => Q.all([@initStoreValues('favLang'), @initStoreValues('favLocale')])


  ###
    Init values with stores
  ###
  @initStoreValues = (i18nValueName) =>
    @checkStores(i18nValueName)                                 # check if value is set into one of the store
    .then => @updateMemoryValueFromStore(i18nValueName)         # @favLang <- Stores
    .catch (err) =>                                             # catch if checkStores() fail
      @initMemoryValueFromBrowser(i18nValueName)                # get init memory values from browser
      .then(=> @setValueToStore i18nValueName)                  # @favLang -> Stores
      .then(=> @checkStores i18nValueName)                      # recheck stores in order to set checking vars
    .then => @checkSyncStoreEqChromeStore(i18nValueName)        # check chromeStoreValue == syncStoreValue
    .catch (err) => @updateChromeStore(i18nValueName)           # if not, update chrome store


  ###
    Know about the supported languages and load the translation files
  ###
  @loadTranslationFiles: =>
    Q.all(@_loadTranslationFile(tag) for tag of @Languages)


  ###
    Fetch translation file
    @param [String] tag Codified language tag
  ###
  @_loadTranslationFile: (tag) ->
    d = ledger.defer()
    url = '/_locales/' + tag + '/messages.json'
    $.ajax
      dataType: "json",
      url: url,
      success: (data) ->
        ledger.i18n.translations[tag] = data
        d.resolve()
    d.promise


  ###
     Check if i18nValueName is set into syncStore OR chromeStore and set store value in memory for further checking
     @param [String] i18nValueName Value you want to check if set into store. Must be 'favLocale' or 'favLang'
     @return [Promise]
   ###
  @checkStores: (i18nValueName) =>
    d = ledger.defer()
    if ledger.storage.sync?
      ledger.storage.sync.get ["__i18n_#{i18nValueName}"], (r) =>
        if r["__i18n_#{i18nValueName}"]?
          @[i18nValueName].syncStoreIsSet = true
          @[i18nValueName].syncStoreValue = if Array.isArray(r["__i18n_#{i18nValueName}"]) then r["__i18n_#{i18nValueName}"][0] else r["__i18n_#{i18nValueName}"]
          d.resolve("ledger.storage.sync.get r.__i18n_#{i18nValueName} " + r["__i18n_#{i18nValueName}"] + " is set into synced Store")
        else
          @[i18nValueName].syncStoreIsSet = false
          d.reject("ledger.storage.sync.get r.__i18n_#{i18nValueName} " + r["__i18n_#{i18nValueName}"] + " is not set into synced Store")
    else
      @chromeStore.get ["__i18n_#{i18nValueName}"], (r) =>
        if r["__i18n_#{i18nValueName}"]?
          @[i18nValueName].chromeStoreIsSet = true
          @[i18nValueName].chromeStoreValue =  if Array.isArray(r["__i18n_#{i18nValueName}"]) then r["__i18n_#{i18nValueName}"][0] else r["__i18n_#{i18nValueName}"]
          d.resolve("@chromeStore.get r.__i18n_#{i18nValueName} " + r["__i18n_#{i18nValueName}"] + " is set into chromeStore")
        else
          @[i18nValueName].chromeStoreIsSet = false
          d.reject("@chromeStore.get r.__i18n_#{i18nValueName} " + r["__i18n_#{i18nValueName}"] + " is not set into chromeStore")
    d.promise


  ###
    Load i18n memoryValue from one of the store
    @param [String] i18nValueName Value type to load, 'favLocale' or 'favLang'
    @return [Promise]
  ###
  @updateMemoryValueFromStore: (i18nValueName) =>
    d = ledger.defer()
    if ledger.storage.sync?
      # Set i18nValueName from syncStore
      ledger.storage.sync.get ["__i18n_#{i18nValueName}"], (r) =>
        @[i18nValueName].memoryValue = if Array.isArray(r["__i18n_#{i18nValueName}"]) then r["__i18n_#{i18nValueName}"][0] else r["__i18n_#{i18nValueName}"]
        d.resolve()
    else
      # Set i18nValueName from chromeStore
      @chromeStore.get ["__i18n_#{i18nValueName}"], (r) =>
        @[i18nValueName].memoryValue = if Array.isArray(r["__i18n_#{i18nValueName}"]) then r["__i18n_#{i18nValueName}"][0] else r["__i18n_#{i18nValueName}"]
        d.resolve()
    d.promise


  ###
    Update Locale chrome store
    @param [String] i18nValueName Value you want to update. Must be 'favLocale' or 'favLang'
    @param [function] callback Callback
  ###
  @updateChromeStore: (i18nValueName, callback = undefined) =>
    d = ledger.defer(callback)
    data = {}
    if ledger.storage.sync? and @[i18nValueName].syncStoreValue?
      @[i18nValueName].chromeStoreValue = @[i18nValueName].syncStoreValue
      data["__i18n_#{i18nValueName}"] = @[i18nValueName].chromeStoreValue
      @chromeStore.set data, -> d.resolve()
    else
      d.resolve()
    d.promise


  ###
    Set i18nValueName into stores from memory
  ###
  @setValueToStore: (i18nValueName) =>
    d = ledger.defer()
    _data = {}
    _data["__i18n_#{i18nValueName}"] = @[i18nValueName].memoryValue
    store = ledger.storage.sync or @chromeStore
    store.set _data, -> d.resolve().promise


  ###
  ###
  @initBrowserAcceptLanguages: =>
    d = ledger.defer()
    # Get user favorite languages with regions set in browser prefs and store into @browserAcceptLanguages
    chrome.i18n.getAcceptLanguages (requestedLocales) =>
      @browserAcceptLanguages = _.map requestedLocales, (obj) -> obj
      d.resolve()
    d.promise


  ###
    Set @favLang.memoryValue with one of the browser accept language (@browserAcceptLanguages), fallback on browser UI language
  ###
  @initMemoryValueFromBrowser: (i18nValueName) =>
    d = ledger.defer()
    done = false
    # Load user language of his Chrome browser UI version into browserUiLang
    browserUiLang = chrome.i18n.getUILanguage()
    for tag in @browserAcceptLanguages
      # Take the first tag that is part of our supported languages (@Languages)
      if tag.substr(0, 2) in Object.keys(@Languages) and not done
        @[i18nValueName].memoryValue = if i18nValueName is 'favLang' and (tag.length > 2) then tag.substr(0, 2) else tag
        done = true
      # Fallback to browser UI language if vars are still not set
      @favLang.memoryValue = browserUiLang if not @favLang.memoryValue?
      @favLocale.memoryValue = browserUiLang if not @favLocale.memoryValue?
      # Fallback to English if the favorite language is not supported
      @favLang.memoryValue = 'en' if @favLang.memoryValue not in Object.keys(@Languages)
      d.resolve()
    d.promise


  @mostAcceptedLanguage: => @browserAcceptLanguages[0]


  ###
    Check if Chrome store values equals Sync Store values
    @param [String] i18nValueName Value you want to check. Must be 'favLocale' or 'favLang'
  ###
  @checkSyncStoreEqChromeStore: (i18nValueName) =>
    d = ledger.defer()
    if ledger.storage.sync?
      if (@[i18nValueName].chromeStoreValue is @[i18nValueName].syncStoreValue) and @[i18nValueName].syncStoreValue?
        @[i18nValueName].storesAreSync = true
        d.resolve()
      else
        @[i18nValueName].storesAreSync = false
        d.reject('Stores are not sync')
    else
      d.resolve()
    d.promise


  ###
    Set user locale (region) into memory and both stores by UI
    @example Set a locale
      ledger.i18n.setLocaleByUI('en-GB')
    @param [String] tag Codified (BCP 47) language tag - Official list here : http://www.iana.org/assignments/language-subtag-registry/language-subtag-registry
  ###
  @setLocaleByUI: (locale) =>
    d = ledger.defer()
    tag = _.str.replace(locale, '_', '-')
    @chromeStore.set {__i18n_favLocale: tag}, =>
      ledger.storage.sync.set {__i18n_favLocale: tag}, =>
        _.extend @favLocale,
          @favLocale =
            memoryValue: tag
            chromeStoreValue: tag
            syncStoreValue: tag
            syncStoreIsSet: true
            chromeStoreIsSet: true
            storesAreSync: true
        @setMomentLocale()
        d.resolve()
    d.promise


  ###
    Set user favorite language into memory and both stores By UI
    @param [String] tag Codified (BCP 47) language tag - Official list here : http://www.iana.org/assignments/language-subtag-registry/language-subtag-registry
  ###
  @setFavLangByUI: (tag) =>
    d = ledger.defer()
    throw new Error 'Tag language must be two characters. Use ledger.i18n.setLocaleByUI() if you want to set the region' if tag.length > 2
    # Check if it is a supported language
    if tag not in Object.keys(@Languages)
      tag = 'en'
      throw new Error 'Language not yet supported! English set as default.'
    @chromeStore.set {__i18n_favLang: tag}, =>
      ledger.storage.sync.set {__i18n_favLang: tag}, =>
        _.extend @favLang,
          @favLang =
            memoryValue: tag
            chromeStoreValue: tag
            syncStoreValue: tag
            syncStoreIsSet: true
            chromeStoreIsSet: true
            storesAreSync: true
        d.resolve()
    d.promise
