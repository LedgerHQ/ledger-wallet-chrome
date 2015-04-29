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
      # Lang: Manage text translation
      @loadUserBrowserAcceptLangs()
      .then =>
        @checkLangIntoStores() # is Lang set into one of the store ?
      .then (info) =>
        #l info, ' - Loading favLang'
        @loadLang()# @favLang <- Stores
      .catch (err) =>
        #l 'Get initial value for Lang and Locale and send it to stores - ', err
        @getLangAndLocaleFromBrowserAndStoreIt()
      .then () =>
        #l 'Lang: set chromeStoreValue and syncStoreValue from stores'
        @setFavLangStoreValues()# set chromeStoreValue and syncStoreValue
      .then () =>
        #l 'Lang: check sync'
        @checkFavLangSyncStoreEqChromeStore()
      .catch (err) =>
        #l err, ' - Lang: syncing'
        @syncLangStores()
      # Locale: Manage date, time and currency converters
      .then () =># is Locale set into one of the store ?
        #l '@checkLocaleIntoStores'
        @checkLocaleIntoStores()
      .then (info) =>
        #l info, ' - Loading locale'
        @loadLocale()# @Locale <- Stores
      .catch (err) =>
        l err
      .then () =>
        #l 'Locale: set storevalues'
        @setLocaleStoreValues()# set chromeStoreValue and syncStoreValue
      .then () =>
        #l 'Locale: check sync'
        @checkFavLocaleSyncStoreEqChromeStore()
      .catch (err) =>
        #l err, ' - Locale: syncing'
        @syncLocaleStores()
      .then () =>
        #l 'set Moment.js Locale'
        @setMomentLocale()

    @loadTranslationFiles()
    .then () =>
      initLangAndLocale()
    .catch (err) -> l err
    .then () =>
      cb()
    .catch (err) -> l err
    .done()
    ledger.app.on('wallet:initialized', initLangAndLocale)



  # General ####

  ###
    Know about the supported languages and load the translation files
  ###
  @loadTranslationFiles: () =>
    deferred = Q.defer()
    for tag of @Languages
      @loadTrad(tag)
    deferred.resolve()
    return deferred.promise


  ###
    Get lang form browser prefs and store it 
  ###
  @getLangAndLocaleFromBrowserAndStoreIt: () =>
    @loadUserBrowserUiLang()
    .then(@loadUserBrowserAcceptLangs)
    .then(@setLangAndLocaleMemoryFromBrowser)
    .then(@setFavLang)# @favLang -> Stores
    .then(@setLocale)# @favLocale -> Stores


  ###
    Set favLang.chromeStoreValue and @favLang.syncStoreValue from the stores
  ###
  @setFavLangStoreValues: () =>
    deferred = Q.defer()
    if ledger.storage.sync?
      ledger.storage.sync.get '__i18n_favLang', (r) =>
        if Array.isArray(r.__i18n_favLang)
          r.__i18n_favLang = r.__i18n_favLang[0]
        #l 'syncstore', r.__i18n_favLang
        @favLang.syncStoreValue = r.__i18n_favLang
        deferred.resolve()
    else
      @chromeStore.get '__i18n_favLang', (r) =>
        if Array.isArray(r.__i18n_favLang)
          r.__i18n_favLang = r.__i18n_favLang[0]
        @favLang.chromeStoreValue = r.__i18n_favLang
        #l 'chromestore', r.__i18n_favLang
        deferred.resolve()
    return deferred.promise


  ###
    Set favLocale.chromeStoreValue and @favLocale.syncStoreValue from both stores
  ###
  @setLocaleStoreValues: () =>
    deferred = Q.defer()
    @chromeStore.get '__i18n_favLocale', (r) =>
      if Array.isArray(r.__i18n_favLocale)
        r.__i18n_favLocale = r.__i18n_favLocale[0]
      @favLocale.chromeStoreValue = r.__i18n_favLocale

      if ledger.storage.sync?
        ledger.storage.sync.get '__i18n_favLocale', (r) =>
          if Array.isArray(r.__i18n_favLocale)
            r.__i18n_favLocale = r.__i18n_favLocale[0]
          @favLocale.syncStoreValue = r.__i18n_favLocale
          deferred.resolve()
      else
        deferred.resolve()
    return deferred.promise


  ###
    Check if fav lang sync Store values equals Chrome store values
  ###
  @checkFavLangSyncStoreEqChromeStore: () =>
    deferred = Q.defer()
    if ledger.storage.sync?
      if (@favLang.syncStoreValue == @favLang.chromeStoreValue) and @favLang.syncStoreValue isnt undefined
        @favLang.storesAreSync = true
        deferred.resolve()
      else
        @favLang.storesAreSync = false
        deferred.reject('Stores are not sync')
    else
      deferred.resolve()
    return deferred.promise


  ###
    set @favLang.chromeStoreValue as @favLang.syncStoreValue and update chrome store
  ###
  @syncLangStores: () =>
    deferred = Q.defer()
    if ledger.storage.sync? and @favLang.syncStoreValue?
      @favLang.chromeStoreValue = @favLang.syncStoreValue
      # Send chromeStoreValue to chrome store
      #l 'set @favLang.syncStoreValue ' + @favLang.syncStoreValue + ' to @favLang.chromeStoreValue'
      @chromeStore.set({__i18n_favLang: @favLang.chromeStoreValue})
    deferred.resolve()
    return deferred.promise


  ###
    set @favLocale.chromeStoreValue as @favLocale.syncStoreValue and update chrome store
  ###
  @syncLocaleStores: () =>
    deferred = Q.defer()
    if ledger.storage.sync?
      @favLocale.chromeStoreValue = @favLocale.syncStoreValue
      # Send chromeStoreValue to chrome store
      @chromeStore.set({__i18n_favLocale: @favLocale.chromeStoreValue})
    deferred.resolve()
    return deferred.promise


  ###
    Check if locale sync Store values equals Chrome store values
  ###
  @checkFavLocaleSyncStoreEqChromeStore: () =>
    deferred = Q.defer()
    if ledger.storage.sync?
      if (@favLocale.syncStoreValue == @favLocale.chromeStoreValue) and @favLocale.syncStoreValue isnt undefined
        @favLocale.storesAreSync = true
        deferred.resolve()
      else
        @favLocale.storesAreSync = false
        deferred.reject('Stores are not sync')
    else
      deferred.resolve()
    return deferred.promise


  ###
    Check if favLocale.memoryValue corresponds to @favLang.memoryValue

  @checkLangAndLocaleCorrespondence: () =>
    deferred = Q.defer()
    if @favLocale.memoryValue and @favLang.memoryValue
      if @favLocale.memoryValue.substr(0, 2) isnt @favLang.memoryValue
        @favLocale.memoryValue = @favLang.memoryValue
        l 'Lang and Locale correspondence was not correct. Locale updated!'
    deferred.resolve()
    return deferred.promise
  ###


  ###
    Load user language of his Chrome browser UI version into @browserUiLang
  ###
  @loadUserBrowserUiLang: () =>
    deferred = Q.defer()
    @browserUiLang = _.str.replace(chrome.i18n.getUILanguage(), '-', '_')
    deferred.resolve()
    return deferred.promise


  ###
    Get user favorite languages with regions set in his Chrome browser preferences and store it in @browserAcceptLanguages variable

    @return [Promise] promise Promise containing the user favorite languages with regions
  ###
  @loadUserBrowserAcceptLangs: () =>
    deferred = Q.defer()
    chrome.i18n.getAcceptLanguages (requestedLocales) =>
      @browserAcceptLanguages = _.map(requestedLocales, (obj) -> return _.str.replace(obj, '-', '_'))
      deferred.resolve()
    return deferred.promise

  @mostAcceptedLanguage: => @browserAcceptLanguages[0]

  ###
    Set @favLang.memoryValue with one of the browser accept language (@browserAcceptLanguages), fallback on browser UI language
  ###
  @setLangAndLocaleMemoryFromBrowser: () =>
    deferred = Q.defer()
    done = false
    if @browserAcceptLanguages?
      for tag in @browserAcceptLanguages
        # Take the first tag that is part of our supported languages (@Languages)
        if tag.substr(0, 2) in Object.keys(@Languages) and not done
          # tag xx
          if tag.length < 3
            @favLang.memoryValue = tag
            # Set the locale as same as the lang
            @favLocale.memoryValue = tag
          # tag xx-xx
          else
            @favLocale.memoryValue = tag
            tag = tag.substr(0, 2)
            @favLang.memoryValue = tag
          done = true
    # Fallback to browser UI language if vars are still not set
    if not @favLang.memoryValue?
      @favLang.memoryValue = @browserUiLang
    if not @favLocale.memoryValue?
      @favLocale.memoryValue = @browserUiLang
    # Fallback to English if the favorite language is not supported
    if @favLang.memoryValue not in Object.keys(@Languages)
      @favLang.memoryValue = 'en'
    deferred.resolve()
    return deferred.promise


  ###
    Set user favorite language into stores from memory
  ###
  @setFavLang: () =>
    # set tag language to one of the store
    if ledger.storage.sync?
      #l 'set tag to sync store'
      ledger.storage.sync.set({__i18n_favLang: @favLang.memoryValue})
    else
      @chromeStore.set({__i18n_favLang: @favLang.memoryValue})
    # Update @syncStoreIsSet and @chromeStoreIsSet
    @checkLangIntoStores()
    # Update @syncStoreValue and @chromeStoreValue
    .then(@setFavLangStoreValues)


  ###
    Set user favorite language into memory and both stores By UI

    @param [String] tag Codified (BCP 47) language tag - Official list here : http://www.iana.org/assignments/language-subtag-registry/language-subtag-registry
  ###
  @setFavLangByUI: (tag) =>
    # If tag language is set manually
    if tag?
      if tag.length > 2
        throw new Error 'Tag language must be two characters. Use ledger.i18n.setLocale() if you want to set the region'
      # Check if it is a supported language
      if tag in Object.keys(@Languages)
        @favLang.memoryValue = tag
      else
        @favLang.memoryValue = 'en'
        throw new Error 'Language not yet supported! English set as default.'
    @chromeStore.set({__i18n_favLang: tag})
    if ledger.storage.sync?
      #l 'set tag to sync store'
      ledger.storage.sync.set({__i18n_favLang: tag})
    # Update everything
    @setFavLangStoreValues()# set chromeStoreValue and syncStoreValue
    .then () =>
      # l 'Lang: check sync'
      @checkFavLangSyncStoreEqChromeStore()
    .catch (err) =>
      # l err, ' - Lang: syncing'
      @syncLangStores()


  ###
    Set user locale (region) to one of the stores

    @param [String] tag Codified (BCP 47) language tag - Official list here : http://www.iana.org/assignments/language-subtag-registry/language-subtag-registry
  ###
  @setLocale: () =>
    # set tag language to one of the store
    if ledger.storage.sync?
      #l 'set locale tag to sync store'
      ledger.storage.sync.set({__i18n_favLocale: @favLocale.memoryValue})
    else
      #l 'set locale tag to chrome store'
      @chromeStore.set({__i18n_favLocale: @favLocale.memoryValue})
    # Update @syncStoreIsSet and @chromeStoreIsSet
    @checkLocaleIntoStores()
    # Update @syncStoreValue and @chromeStoreValue
    .then(@setLocaleStoreValues)
    # Set the locale for Moment.js
    .then(@setMomentLocale)


  ###
    Set user locale (region) into memory and both stores by UI

    @param [String] tag Codified (BCP 47) language tag - Official list here : http://www.iana.org/assignments/language-subtag-registry/language-subtag-registry
  ###
  @setLocaleByUI: (tag) =>
    # If tag language is set manually
    if tag?
      @favLocale.memoryValue = tag
    @chromeStore.set({__i18n_favLocale: @favLocale.memoryValue})
    if ledger.storage.sync?
      #l 'set locale tag to sync store'
      ledger.storage.sync.set({__i18n_favLocale: @favLocale.memoryValue})
    # Update @syncStoreIsSet and @chromeStoreIsSet
    @checkLocaleIntoStores()
    # Update @syncStoreValue and @chromeStoreValue
    .then(@setLocaleStoreValues)
    # Set the locale for Moment.js
    .then(@setMomentLocale)


  ###
    Load @favLang.memoryValue from syncStore or chromeStore

    @return [Promise]
  ###
  @loadLang: () =>
    deferred = Q.defer()
    if ledger.storage.sync?
      # Set @favLang from syncStore
      ledger.storage.sync.get '__i18n_favLang', (r) =>
        if Array.isArray(r.__i18n_favLang)
          r.__i18n_favLang = r.__i18n_favLang[0]
        @favLang.memoryValue = r.__i18n_favLang
    else
      # Set favLang from chromeStore
      @chromeStore.get '__i18n_favLang', (r) =>
        if Array.isArray(r.__i18n_favLang)
          r.__i18n_favLang = r.__i18n_favLang[0]
        @favLang.memoryValue = r.__i18n_favLang
    deferred.resolve()
    return deferred.promise


  ###
    Check if FavLang is set into syncStore and chromeStore

    @return [Promise]
  ###
  @checkLangIntoStores: () =>
    deferred = Q.defer()
    if ledger.storage.sync?
      ledger.storage.sync.get '__i18n_favLang', (r) =>
        if r.__i18n_favLang isnt undefined
          @favLang.syncStoreIsSet = true
          deferred.resolve('ledger.storage.sync.get r.__i18n_favLang ' + r.__i18n_favLang + ' is set into syncStore')
        else
          @favLang.syncStoreIsSet = false
          deferred.reject('ledger.storage.sync.get r.__i18n_favLang' + r.__i18n_favLang + ' is not set into syncStore')
    else
      @chromeStore.get '__i18n_favLang', (r) =>
        if r.__i18n_favLang isnt undefined
          @favLang.chromeStoreIsSet = true
          deferred.resolve('@chromeStore.get r.__i18n_favLang ' + r.__i18n_favLang + ' is set into chromeStore')
        else
          @favLang.chromeStoreIsSet = false
          deferred.reject('@chromeStore.get r.__i18n_favLang ' + r.__i18n_favLang + ' is not set into chromeStore')
    return deferred.promise


  ###
    Remove key 'i18n_favLang' from sync Store
  ###
  @removeUserFavLangSyncStore: () =>
    ledger.storage.sync.remove('__i18n_favLang', l)
    @checkLangIntoStores()


  ###
    Remove key 'i18n_favLang' from chrome Store
  ###
  @removeUserFavLangChromeStore: () =>
    @chromeStore.remove('__i18n_favLang', l)
    @checkLangIntoStores()



  ###
    Load @favLocale.memoryValue from one of the store

    @return [Promise]
  ###
  @loadLocale: () =>
    deferred = Q.defer()
    if ledger.storage.sync?
      # Set userFavLocale from syncStore
      ledger.storage.sync.get '__i18n_favLocale', (r) =>
        if Array.isArray(r.__i18n_favLocale)
          r.__i18n_favLocale = r.__i18n_favLocale[0]
        # l r.__i18n_favLocale
        @favLocale.memoryValue = r.__i18n_favLocale
        deferred.resolve()
    else
      # Set userFavLocale from chromeStore
      @chromeStore.get '__i18n_favLocale', (r) =>
        if Array.isArray(r.__i18n_favLocale)
          r.__i18n_favLocale = r.__i18n_favLocale[0]
        @favLocale.memoryValue = r.__i18n_favLocale
        #l r.__i18n_favLocale
        deferred.resolve()
    return deferred.promise


  ###
    Check if @favLocale is set into syncStore or chromeStore

    @return [Promise]
  ###
  @checkLocaleIntoStores: () =>
    deferred = Q.defer()
    if ledger.storage.sync?
      ledger.storage.sync.get '__i18n_favLocale', (r) =>
        if r.__i18n_favLocale isnt undefined
          @favLocale.syncStoreIsSet = true
          deferred.resolve('ledger.storage.sync.get r.__i18n_favLocale ' + r.__i18n_favLocale + ' is set into synced Store')
        else
          @favLocale.syncStoreIsSet = false
          deferred.reject('ledger.storage.sync.get r.__i18n_favLocale ' + r.__i18n_favLocale + ' is not set into synced Store')
    else
      @chromeStore.get '__i18n_favLocale', (r) =>
        if r.__i18n_favLocale isnt undefined
          @favLocale.chromeStoreIsSet = true
          deferred.resolve('@chromeStore.get r.__i18n_favLocale ' + r.__i18n_favLocale + ' is set into chromeStore')
        else
          @favLocale.chromeStoreIsSet = false
          deferred.reject('@chromeStore.get r.__i18n_favLocale ' + r.__i18n_favLocale + ' is not set into chromeStore')
    return deferred.promise


  ###
    Remove key 'i18n_favLocale' from sync Store
  ###
  @removeLocaleSyncStore: () =>
    ledger.storage.sync.remove('__i18n_favLocale', l)
    @checkLocaleIntoStores()


  ###
    Remove key 'i18n_favLocale' from chrome Store
  ###
  @removeLocaleChromeStore: () =>
    @chromeStore.remove('__i18n_favLocale', l)
    @checkLocaleIntoStores()


  ###
    Fetch translation file

    @param [String] tag Codified language tag
  ###
  @loadTrad: (tag) ->
    url = '/_locales/' + tag + '/messages.json'
    $.ajax
      dataType: "json",
      url: url,
      success: (data) ->
        ledger.i18n.translations[tag] = data


  ###
   Set the locale for Moment.js
  ###
  @setMomentLocale: () =>
    moment.locale(@favLocale.memoryValue)


  ###
    Translate a message id to a localized text

    @param [String] messageId Unique identifier of the message
    @return [String] localized message
  ###
  @t: (messageId) =>
    messageId = _.string.replace(messageId, '.', '_')
    key = @.translations[@favLang.memoryValue][messageId]
    if not key? or not key['message']?
      return messageId
    res = @.translations[@favLang.memoryValue][messageId]['message']
    return res if res? and res.length > 0
    return messageId


  # Formatters ######

  ###
    Formats amounts with currency symbol

    @param [String] amount The amount to format
    @param [String] currency The currency
    @return [String] The formatted amount
  ###
  @formatAmount: (amount, currency) ->
    locale = _.str.replace(@favLocale.memoryValue, '_', '-')
    if amount?
      testValue = (amount).toLocaleString(locale, {style: "currency", currency: currency, currencyDisplay: "code", minimumFractionDigits: 2})
      value = (amount).toLocaleString(locale, {minimumFractionDigits: 2})
    else
      testValue = (0).toLocaleString(locale, {style: "currency", currency: currency, currencyDisplay: "code", minimumFractionDigits: 2})
      value = '--'
    if _.isNaN(parseInt(testValue.charAt(0)))
      value = currency + ' ' + value
    else
      value = value + ' ' + currency
    value

  @formatNumber: (number) ->
    locale = _.str.replace(@favLocale.memoryValue, '_', '-')
    return number.toLocaleString(locale, {minimumFractionDigits: 2})

  ###
    Formats date and time

    @param [Date] dateTime The date and time to format
    @return [String] The formatted date and time
  ###
  @formatDateTime: (dateTime) ->
    moment(dateTime).format @t 'common.date_time_format'


  ###
    Formats date

    @param [Date] date The date to format
    @return [String] The formatted date
  ###
  @formatDate: (date) ->
    moment(date).format @t 'common.date_format'


  ###
    Formats time

    @param [Date] time The time to format
    @return [String] The formatted time
  ###
  @formatTime: (time) ->
    moment(time).format @t 'common.time_format'


  @getAllLocales: (callback) ->
    $.getJSON '../src/i18n/regions.json', (data) ->
      callback?(data)

@t = ledger.i18n.t