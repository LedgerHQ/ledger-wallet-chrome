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

    # Know about the supported languages and load the translation files
    @Languages = Object.keys(@Languages)
    for tag in @Languages
      @loadTrad(tag)

    initLangAndLocale = () =>
      # Lang: Manage text translation
      @checkLangIntoStores()# is Lang set into one of the store ?
      .then (info) =>
        l info, ' - Loading favLang'
        @loadUserFavLang()# @favLang <- Stores
      .catch (err) =>
        l err, ' - setFavLang'
        @setFavLang()# @favLang -> Stores
      .then () =>
        l 'Lang: set chromeStoreValue and syncStoreValue from stores'
        @setFavLangStoreValues()# set chromeStoreValue and syncStoreValue
      .then () =>
        l 'Lang: check sync'
        @checkFavLangSyncStoreEqChromeStore()
      .catch (err) =>
        l err, ' - Lang: syncing'
        @syncLangStores()
      # Locale: Manage date, time and currency converters
      .then () =>
        l 'check locale into stores'
        @checkLocaleIntoStores()# is Locale set into one of the store ?
      .then (info) =>
        l info, ' - Loading locale'
        @loadLocale()# @Locale <- Stores
      .catch (err) =>
        l err, ' - set locale to stores'
        @setLocale()# @Locale -> Stores
      .then () =>
        l 'Locale: set storevalues'
        @setLocaleStoreValues()# set chromeStoreValue and syncStoreValue
      .then () =>
        l 'Locale: check sync'
        @checkFavLocaleSyncStoreEqChromeStore()
      .catch (err) =>
        l err, ' - Locale: syncing'
        @syncLocaleStores()
      .finally () =>
        l 'set Moment.js Locale'
        @setMomentLocale()
      .done()

    initLangAndLocale()
    ledger.app.on('wallet:initialized', initLangAndLocale)

    cb()



  # General ####

  ###
    Set favLang.chromeStoreValue and @favLang.syncStoreValue from the stores
  ###
  @setFavLangStoreValues: () =>
    deferred = Q.defer()
    if ledger.storage.sync?
      ledger.storage.sync.get 'i18n_favLang', (r) =>
        if Array.isArray(r.i18n_favLang)
          r.i18n_favLang = r.i18n_favLang[0]
        #l 'syncstore', r.i18n_favLang
        @favLang.syncStoreValue = r.i18n_favLang
        deferred.resolve()
    else
      @chromeStore.get 'i18n_favLang', (r) =>
        if Array.isArray(r.i18n_favLang)
          r.i18n_favLang = r.i18n_favLang[0]
        @favLang.chromeStoreValue = r.i18n_favLang
        #l 'chromestore', r.i18n_favLang
        deferred.resolve()
    return deferred.promise


  ###
    Set favLocale.chromeStoreValue and @favLocale.syncStoreValue from the stores
  ###
  @setLocaleStoreValues: () =>
    deferred = Q.defer()
    @chromeStore.get 'i18n_favLocale', (r) =>
      if Array.isArray(r.i18n_favLocale)
        r.i18n_favLocale = r.i18n_favLocale[0]
      @favLocale.chromeStoreValue = r.i18n_favLocale

      if ledger.storage.sync?
        ledger.storage.sync.get 'i18n_favLocale', (r) =>
          if Array.isArray(r.i18n_favLocale)
            r.i18n_favLocale = r.i18n_favLocale[0]
          @favLocale.syncStoreValue = r.i18n_favLocale
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
      @chromeStore.set({i18n_favLang: @favLang.chromeStoreValue})
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
      @chromeStore.set({i18n_favLocale: @favLocale.chromeStoreValue})
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
    @browserUiLang = chrome.i18n.getUILanguage()
    deferred.resolve()
    return deferred.promise


  ###
    Get user favorite languages with regions set in his Chrome browser preferences and store it in @browserAcceptLanguages variable

    @return [Promise] promise Promise containing the user favorite languages with regions
  ###
  @loadUserBrowserAcceptLangs: () =>
    deferred = Q.defer()
    chrome.i18n.getAcceptLanguages (requestedLocales) =>
      @browserAcceptLanguages = requestedLocales
      deferred.resolve()
    return deferred.promise


  ###
    Set @favLang from browser accept languages
  ###
  @setFavLangFromBrowserAcceptLanguages: () =>
    deferred = Q.defer()
    # Select language tag without region
    i = 0
    for str in @browserAcceptLanguages
      if @browserAcceptLanguages[i].length > 2
        i++
        @favLang.memoryValue = @browserAcceptLanguages[i]
      else
        @favLocale.memoryValue = @browserAcceptLanguages[i]
    deferred.resolve()
    return deferred.promise


  # User Favorite Language ####

  ###
    Set user favorite language into stores
  ###
  @setFavLang: () =>
    deferred = Q.defer()
    @loadUserBrowserUiLang()
    .then(@loadUserBrowserAcceptLangs)
    .then(@setFavLangFromBrowserAcceptLanguages)
    .catch (err) -> l(err)
    .done()
    tag = @favLang.memoryValue || @browserUiLang
    l @favLang.memoryValue
    l tag
    # set tag language to one of the store
    #l 'set tag to chrome store'
    @chromeStore.set({i18n_favLang: tag})
    if ledger.storage.sync?
      #l 'set tag to sync store'
      ledger.storage.sync.set({i18n_favLang: tag})
    deferred.resolve()
    return deferred.promise


  ###
    Set user favorite language into stores By UI

    @param [String] tag Codified (BCP 47) language tag - Official list here : http://www.iana.org/assignments/language-subtag-registry/language-subtag-registry
  ###
  @setFavLangByUI: (tag) =>
    deferred = Q.defer()
    # If tag language is set manually
    if tag?
      if tag.length > 2
        throw new Error 'Tag language must be two characters. Use ledger.i18n.setLocale() if you want to set the region'
      @favLang.memoryValue = tag
    @chromeStore.set({i18n_favLang: tag})
    if ledger.storage.sync?
      #l 'set tag to sync store'
      ledger.storage.sync.set({i18n_favLang: tag})
    # Update everything
    @setFavLangStoreValues() # set chromeStoreValue and syncStoreValue
    .then () =>
      #l 'Lang: check sync'
      @checkFavLangSyncStoreEqChromeStore()
    .catch (err) =>
      #l err, ' - Lang: syncing'
      @syncLangStores()
    deferred.resolve()
    return deferred.promise


  ###
    Load @favLang.memoryValue from syncStore or chromeStore

    @return [Promise]
  ###
  @loadUserFavLang: () =>
    deferred = Q.defer()
    # Set favLang from chromeStore
    @chromeStore.get 'i18n_favLang', (r) =>
      if Array.isArray(r.i18n_favLang)
        r.i18n_favLang = r.i18n_favLang[0]
      @favLang.memoryValue = r.i18n_favLang
    if ledger.storage.sync?
      # Set @favLang from syncStore
      ledger.storage.sync.get 'i18n_favLang', (r) =>
        if Array.isArray(r.i18n_favLang)
          r.i18n_favLang = r.i18n_favLang[0]
        @favLang.memoryValue = r.i18n_favLang
    deferred.resolve()
    return deferred.promise


  ###
    Check if FavLang is set into syncStore and chromeStore

    @return [Promise]
  ###
  @checkLangIntoStores: () =>
    deferred = Q.defer()
    @chromeStore.get 'i18n_favLang', (r) =>
      if r.i18n_favLang isnt undefined
        @favLang.chromeStoreIsSet = true
        deferred.resolve('@chromeStore.get r.i18n_favLang ' + r.i18n_favLang + ' is set into chromeStore')
      else
        @favLang.chromeStoreIsSet = false
        deferred.reject('@chromeStore.get r.i18n_favLang ' + r.i18n_favLang + ' is not set into chromeStore')
    if ledger.storage.sync?
      ledger.storage.sync.get 'i18n_favLang', (r) =>
        if r.i18n_favLang isnt undefined
          @favLang.syncStoreIsSet = true
          deferred.resolve('ledger.storage.sync.get r.i18n_favLang ' + r.i18n_favLang + ' is set into syncStore')
        else
          @favLang.syncStoreIsSet = false
          deferred.reject('ledger.storage.sync.get r.i18n_favLang is not set into syncStore')
    return deferred.promise


  ###
    Remove key 'i18n_favLang' from sync Store
  ###
  @removeUserFavLangSyncStore: () =>
    ledger.storage.sync.remove('i18n_favLang', l)
    @checkLangIntoStores()


  ###
    Remove key 'i18n_favLang' from chrome Store
  ###
  @removeUserFavLangChromeStore: () =>
    @chromeStore.remove('i18n_favLang', l)
    @checkLangIntoStores()


  # User Favorite Locale ####

  ###
    Set user locale (region) to one of the stores

    @param [String] tag Codified (BCP 47) language tag - Official list here : http://www.iana.org/assignments/language-subtag-registry/language-subtag-registry
  ###
  @setLocale: (tag) =>
    deferred = Q.defer()
    # If tag language is set manually
    if tag?
      @favLocale.memoryValue = tag
    else
      tag ?= @favLocale.memoryValue || @browserUiLang
      @favLocale.memoryValue = tag
    #l 'set locale tag to chrome store'
    @chromeStore.set({i18n_favLocale: tag})
    # set tag language to one of the store
    if ledger.storage.sync?
      #l 'set locale tag to sync store'
      ledger.storage.sync.set({i18n_favLocale: tag})
    # Update @syncStoreIsSet and @chromeStoreIsSet
    @checkLocaleIntoStores()
    # Update @syncStoreValue and @chromeStoreValue
    .then(@setLocaleStoreValues)
    .catch (err) -> l err
    .done
    # Set the locale for Moment.js
    moment.locale(@favLocale.memoryValue.toLowerCase())
    deferred.resolve()
    return deferred.promise



  ###
    Set and Get @userFavLocale from one of the store

    @return [Promise]
  ###
  @loadLocale: () =>
    deferred = Q.defer()
    if ledger.storage.sync?
      # Set userFavLocale from syncStore
      ledger.storage.sync.get 'i18n_favLocale', (r) =>
        if Array.isArray(r.i18n_favLocale)
          r.i18n_favLocale = r.i18n_favLocale[0]
        # l r.i18n_favLocale
        @favLocale.memoryValue = r.i18n_favLocale
        deferred.resolve()
    else
      # Set userFavLocale from chromeStore
      @chromeStore.get 'i18n_favLocale', (r) =>
        if Array.isArray(r.i18n_favLocale)
          r.i18n_favLocale = r.i18n_favLocale[0]
        @favLocale.memoryValue = r.i18n_favLocale
        # l r.i18n_favLocale
        deferred.resolve()
    return deferred.promise


  ###
    Check if @favLocale is set into syncStore or chromeStore

    @return [Promise]
  ###
  @checkLocaleIntoStores: () =>
    deferred = Q.defer()
    if ledger.storage.sync?
      ledger.storage.sync.get 'i18n_favLocale', (r) =>
        if r.i18n_favLocale isnt undefined  # and r.i18n_favLocale is @favLang.memoryValue
          @favLocale.syncStoreIsSet = true
          deferred.resolve('ledger.storage.sync.get r.i18n_favLocale ' + r.i18n_favLocale + ' is set into synced Store')
        else
          @favLocale.syncStoreIsSet = false
          deferred.reject('ledger.storage.sync.get r.i18n_favLocale ' + r.i18n_favLocale + ' is not set into synced Store')
    else
      @chromeStore.get 'i18n_favLocale', (r) =>
        if r.i18n_favLocale isnt undefined
          @favLocale.chromeStoreIsSet = true
          deferred.resolve('@chromeStore.get r.i18n_favLocale ' + r.i18n_favLocale + ' is set into chromeStore')
        else
          @favLocale.chromeStoreIsSet = false
          deferred.reject('@chromeStore.get r.i18n_favLocale ' + r.i18n_favLocale + ' is not set neither into synced Store or chromeStore')
    return deferred.promise


  ###
    Remove key 'i18n_favLocale' from sync Store
  ###
  @removeLocaleSyncStore: () =>
    ledger.storage.sync.remove('i18n_favLocale', l)
    @checkLocaleIntoStores()


  ###
    Remove key 'i18n_favLocale' from chrome Store
  ###
  @removeLocaleChromeStore: () =>
    @chromeStore.remove('i18n_favLocale', l)
    @checkLocaleIntoStores()


  # ######

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
    Translate a message id to a localized text

    @param [String] messageId Unique identifier of the message
    @return [String] localized message
  ###
  @t: (messageId) =>
    messageId = _.string.replace(messageId, '.', '_')
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
    options =
      style: "currency"
      currency: currency
      currencyDisplay: "symbol"
    (amount).toLocaleString(@favLocale.memoryValue, options)


  ###
    Set the locale for Moment.js
  ###
  @setMomentLocale: () =>
    moment.locale(@favLocale.memoryValue.toLowerCase())


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


@t = ledger.i18n.t