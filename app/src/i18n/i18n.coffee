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
  # Language tag that depends on the browser UI language
  @browserUiLang: undefined
  # Supported languages by the app (when translation is done)
  @Languages: {}


  @init: (cb) =>
    @chromeStore = new ledger.storage.ChromeStore('i18n')

    initLangAndLocale = () =>
      ###
        Lang: Manage text translation
      ###
      @loadUserBrowserAcceptLangs()
      .then => @checkStores('favLang')                       # check if value is set into one of the store
      .then => @loadI18nValueFromStore('favLang')            # @favLang <- Stores
      .catch (err) => @getValuesFromBrowserAndStoreIt()      # If value not into stores, get values from browser prefs
      .then => @setFavLangStoreValues()                      # set chromeStoreValue and syncStoreValue
      .then => @checkSyncStoreEqChromeStore('favLang')       # check chromeStoreValue == syncStoreValue
      .catch (err) => @updateChromeStore('favLang')          # if not, update chrome store

      # Locale: Manage date, time and currency converters
      .then => @checkStores('favLocale')                     # check if value is set into one of the store
      .then => @loadI18nValueFromStore('favLocale')          # @Locale <- Stores
      .catch (err) => l err                                  # we already have the 'locale' value
      .then => @setLocaleStoreValues()                       # set chromeStoreValue and syncStoreValue
      .then => @checkSyncStoreEqChromeStore('favLocale')     # check syncStore value == chromeStore value
      .catch (err) => @updateChromeStore('favLocale')        # if not, update chrome store

    @loadTranslationFiles()
    .then => initLangAndLocale()
    .then => @setMomentLocale() # set locale for Moment.js
    .catch (err) -> l err
    .then => cb()
    .catch (err) -> l err
    .done()
    ledger.app.on('wallet:initialized', initLangAndLocale)



  # General ####

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
    Load user language of his Chrome browser UI version into @browserUiLang
  ###
  @loadUserBrowserUiLang: =>
    @browserUiLang = _.str.replace(chrome.i18n.getUILanguage(), '-', '_')
    ledger.defer().resolve().promise


  ###
    Get user favorite languages with regions set in his Chrome browser preferences and store it in @browserAcceptLanguages variable
    @return [Promise] promise Promise containing the user favorite languages with regions
  ###
  @loadUserBrowserAcceptLangs: =>
    d = ledger.defer()
    chrome.i18n.getAcceptLanguages (requestedLocales) =>
      @browserAcceptLanguages = _.map requestedLocales, (obj) -> return _.str.replace(obj, '-', '_')
      d.resolve()
    d.promise

  @mostAcceptedLanguage: => @browserAcceptLanguages[0]


  ###
    Get values from browser prefs and store it
  ###
  @getValuesFromBrowserAndStoreIt: () =>
    @loadUserBrowserUiLang()
    .then(=> @loadUserBrowserAcceptLangs)
    .then(=> @setI18nMemoryValuesFromBrowser)
    .then(=> @setI18nValueToStore 'favLang') # @favLang -> Stores
    .then(=> @setI18nValueToStore 'favLocale') # @favLocale -> Stores


  ###
    Set favLang.chromeStoreValue and @favLang.syncStoreValue from the stores
  ###
  @setFavLangStoreValues: =>
    d = ledger.defer()
    if ledger.storage.sync?
      ledger.storage.sync.get '__i18n_favLang', (r) =>
        r.__i18n_favLang = r.__i18n_favLang[0] if Array.isArray(r.__i18n_favLang)
        l 'syncstore', r.__i18n_favLang
        @favLang.syncStoreValue = r.__i18n_favLang
        d.resolve()
    else
      @chromeStore.get '__i18n_favLang', (r) =>
        r.__i18n_favLang = r.__i18n_favLang[0] if Array.isArray(r.__i18n_favLang)
        @favLang.chromeStoreValue = r.__i18n_favLang
        l 'chromestore', r.__i18n_favLang
        d.resolve()
    d.promise


  ###
    Set favLocale.chromeStoreValue and @favLocale.syncStoreValue from both stores
  ###
  @setLocaleStoreValues: =>
    d = ledger.defer()
    @chromeStore.get '__i18n_favLocale', (r) =>
      r.__i18n_favLocale = r.__i18n_favLocale[0] if Array.isArray(r.__i18n_favLocale)
      @favLocale.chromeStoreValue = r.__i18n_favLocale

      if ledger.storage.sync?
        ledger.storage.sync.get '__i18n_favLocale', (r) =>
          r.__i18n_favLocale = r.__i18n_favLocale[0] if Array.isArray(r.__i18n_favLocale)
          @favLocale.syncStoreValue = r.__i18n_favLocale
          d.resolve()
      else
        d.resolve()
    d.promise


  ###
    Check if Chrome store values equals Sync Store values
    @param [String] i18nValueName Value you want to check. Must be 'favLocale' or 'favLang'
  ###
  @checkSyncStoreEqChromeStore: (i18nValueName) =>
    d = ledger.defer()
    if ledger.storage.sync?
      l @[i18nValueName].chromeStoreValue, @[i18nValueName].syncStoreValue
      l @[i18nValueName].chromeStoreValue is @[i18nValueName].syncStoreValue
      l @[i18nValueName].chromeStoreValue == @[i18nValueName].syncStoreValue
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
    Update Locale chrome store
    @param [String] i18nValueName Value you want to update. Must be 'favLocale' or 'favLang'
    @param [function] callback Callback
  ###
  @updateChromeStore: (i18nValueName, callback = undefined) =>
    d = ledger.defer(callback)
    data = {}
    if ledger.storage.sync? and @[i18nValueName].syncStoreValue?
      l '@[i18nValueName].syncStoreValue', @[i18nValueName].syncStoreValue
      @[i18nValueName].chromeStoreValue = @[i18nValueName].syncStoreValue
      data["__i18n_#{i18nValueName}"] = @[i18nValueName].chromeStoreValue
      @chromeStore.set data, -> d.resolve()
    else
      d.resolve()
    d.promise



  ###
    Set @favLang.memoryValue with one of the browser accept language (@browserAcceptLanguages), fallback on browser UI language
  ###
  setI18nMemoryValuesFromBrowser: =>
    done = false
    if @browserAcceptLanguages?
      for tag in @browserAcceptLanguages
        # Take the first tag that is part of our supported languages (@Languages)
        if tag.substr(0, 2) in Object.keys(@Languages) and not done
          # tag xx
          if tag.length < 3
            @favLocale.memoryValue = @favLang.memoryValue = tag
          # tag xx-xx
          else
            @favLocale.memoryValue = tag
            @favLang.memoryValue = tag.substr(0, 2)
          done = true
    # Fallback to browser UI language if vars are still not set
    @favLang.memoryValue = @browserUiLang if not @favLang.memoryValue?
    @favLocale.memoryValue = @browserUiLang if not @favLocale.memoryValue?
    # Fallback to English if the favorite language is not supported
    @favLang.memoryValue = 'en' if @favLang.memoryValue not in Object.keys(@Languages)
    ledger.defer().resolve().promise


  ###
    Set user locale (region) into memory and both stores by UI

    @param [String] tag Codified (BCP 47) language tag - Official list here : http://www.iana.org/assignments/language-subtag-registry/language-subtag-registry
  ###
  @setLocaleByUI: (tag) =>
    # If tag language is set manually
    @favLocale.memoryValue = tag if tag?
    @chromeStore.set({__i18n_favLocale: @favLocale.memoryValue})
    ledger.storage.sync.set({__i18n_favLocale: @favLocale.memoryValue}) if ledger.storage.sync?
    # Update @syncStoreIsSet and @chromeStoreIsSet
    @checkStores('favLocale')
    # Update @syncStoreValue and @chromeStoreValue
    .then(@setLocaleStoreValues)
    # Set the locale for Moment.js
    .then(@setMomentLocale)


  ###
    Set user favorite language into memory and both stores By UI

    @param [String] tag Codified (BCP 47) language tag - Official list here : http://www.iana.org/assignments/language-subtag-registry/language-subtag-registry
  ###
  @setFavLangByUI: (tag) =>
    # If tag language is set manually
    if tag?
      throw new Error 'Tag language must be two characters. Use ledger.i18n.setLocaleByUI() if you want to set the region' if tag.length > 2
      # Check if it is a supported language
      if tag in Object.keys(@Languages)
        @favLang.memoryValue = tag
      else
        @favLang.memoryValue = 'en'
        throw new Error 'Language not yet supported! English set as default.'
    @chromeStore.set({__i18n_favLang: tag})
    ledger.storage.sync.set({__i18n_favLang: tag}) if ledger.storage.sync?
    # Update everything
    @setFavLangStoreValues() # set chromeStoreValue and syncStoreValue
    .then => @checkSyncStoreEqChromeStore('favLang')
    .catch => @updateChromeStore('favLang')


  ###
    Set i18nValueName into stores from memory
  ###
  @setI18nValueToStore: (i18nValueName) =>
    d = ledger.defer()
    data = {}
    data["__i18n_#{i18nValueName}"] = @[i18nValueName].memoryValue
    l 'data', data
    l 'ledger.storage.sync?', ledger.storage.sync?
    store = ledger.storage.sync? || @chromeStore
    store.set data, =>
      d.resolve @checkStores(i18nValueName)
      .then(if i18nValueName is 'favLocale' then @setLocaleStoreValues else @setFavLangStoreValues)
      .then (=> @setMomentLocale if i18nValueName is 'favLocale')
    d.promise


  ###
    Load i18n memoryValue from one of the store
    @param [String] i18nValueName Value type to load, 'favLocale' or 'favLang'
    @return [Promise]
  ###
  @loadI18nValueFromStore: (i18nValueName) =>
    d = ledger.defer()
    if ledger.storage.sync?
      # Set i18nValueName from syncStore
      ledger.storage.sync.get "__i18n_#{i18nValueName}", (r) =>
        r["__i18n_#{i18nValueName}"] = r["__i18n_#{i18nValueName}"][0] if Array.isArray(r["__i18n_#{i18nValueName}"])
        l 'r["__i18n_#{i18nValueName}"]', r["__i18n_#{i18nValueName}"]
        @[i18nValueName].memoryValue = r["__i18n_#{i18nValueName}"]
        d.resolve()
    else
      # Set i18nValueName from chromeStore
      @chromeStore.get "__i18n_#{i18nValueName}", (r) =>
        r["__i18n_#{i18nValueName}"] = r["__i18n_#{i18nValueName}"][0] if Array.isArray(r["__i18n_#{i18nValueName}"])
        @[i18nValueName].memoryValue = r["__i18n_#{i18nValueName}"]
        d.resolve()
    d.promise


  ###
    Check if i18nValueName is set into syncStore OR chromeStore
    @param [String] i18nValueName Value you want to check if set into store. Must be 'favLocale' or 'favLang'
    @return [Promise]
  ###
  @checkStores: (i18nValueName) =>
    d = ledger.defer()
    l 'ledger.storage.sync?', ledger.storage.sync?
    if ledger.storage.sync?
      l "__i18n_#{i18nValueName}"
      ledger.storage.sync.get "__i18n_#{i18nValueName}", (r) =>
        l r
        if r["__i18n_#{i18nValueName}"]?
          @[i18nValueName].syncStoreIsSet = true
          d.resolve("ledger.storage.sync.get r.__i18n_#{i18nValueName} " + r["__i18n_#{i18nValueName}"] + " is set into synced Store")
        else
          @[i18nValueName].syncStoreIsSet = false
          d.reject("ledger.storage.sync.get r.__i18n_#{i18nValueName} " + r["__i18n_#{i18nValueName}"] + " is not set into synced Store")
    else
      @chromeStore.get "__i18n_#{i18nValueName}", (r) =>
        if r["__i18n_#{i18nValueName}"]?
          @[i18nValueName].chromeStoreIsSet = true
          d.resolve("@chromeStore.get r.__i18n_#{i18nValueName} " + r["__i18n_#{i18nValueName}"] + " is set into chromeStore")
        else
          @[i18nValueName].chromeStoreIsSet = false
          d.reject("@chromeStore.get r.__i18n_#{i18nValueName} " + r["__i18n_#{i18nValueName}"] + " is not set into chromeStore")
    d.promise