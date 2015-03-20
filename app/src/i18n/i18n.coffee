class ledger.i18n

  # chromeStore instance
  @chromeStore: undefined
  # Contain all the translation files
  @translations: {}
  # User favorite language
  @userFavLang: undefined
  # User favorite language and region
  @userFavLocale: undefined
  # Languages + regions tags that represent the user's Chrome browser preferences
  @browserAcceptLanguages: undefined
  # Language tag that depends on the browser UI language
  @browserUiLang: undefined
  # Supported languages by the app (when translation is done)
  @Languages: {}
  # [Boolean] If userFavLang is set into chromeStore or not
  @userFavLangChromeStoreIsSet: undefined
  # [Boolean] If userFavLocale is set into chromeStore or not
  @userFavLocaleChromeStoreIsSet: undefined
  # [Boolean] If userFavLang is set into syncStore or not
  @userFavLangSyncStoreIsSet: undefined
  # [Boolean] If userFavLocale is set into syncStore or not
  @userFavLocaleSyncStoreIsSet: undefined


  @init: (cb) =>

    @chromeStore = new ledger.storage.ChromeStore('i18n')

    # Know about the supported languages and load the translation files
    @Languages = Object.keys(ledger.i18n.Languages)
    for tag in @Languages
      @loadTrad(tag)


    # Manage text translation
    @checkBoolUserFavLang()
    .then =>
      @loadUserFavLang() # @userFavLang <- Stores
    .catch (err) =>
      l err
      @setUserFavLang() # @userFavLang -> Stores

    #.then ->
      # check if sync store === chrome store
    .done()


    # Manage date, time and currency converters
    @checkBoolLocale()
    .then =>
      @loadLocale() # @userFavLocale <- Stores
    .catch (err) =>
      l err
      @setLocale() # @userFavLocale -> Stores

    #.then ->
      # check if sync store === chrome store
    .done()

    cb()



  # General ####

  ###
    Load user language of his Chrome browser UI version into @browserUiLang
  ###
  @loadUserBrowserUiLang: () ->
    ledger.i18n.browserUiLang = chrome.i18n.getUILanguage()


  ###
    Get user favorite languages with regions set in his Chrome browser preferences and store it in @acceptLanguages variable - Async call

    @return [Promise] promise Promise containing the user favorite languages with regions
  ###
  @loadUserBrowserAcceptLangs: () =>
    deferred = Q.defer()
    chrome.i18n.getAcceptLanguages (requestedLocales) =>
      @browserAcceptLanguages = requestedLocales
      deferred.resolve(requestedLocales)

    return deferred.promise


  ###
    Set @userFavLang from browser accept languages
  ###
  @setUserFavLangFromBrowserAcceptLanguages: () ->
    # Select language tag without region
    i = 0
    for str in ledger.i18n.browserAcceptLanguages
      if ledger.i18n.browserAcceptLanguages[i].length > 2
        i++
        ledger.i18n.userFavLang = ledger.i18n.browserAcceptLanguages[i]
      else
        ledger.i18n.userFavLocale = ledger.i18n.browserAcceptLanguages[i]


  # User Favorite Language ####

  ###
    Set user favorite language into stores

    @param [String] tag Codified (BCP 47) language tag - Official list here : http://www.iana.org/assignments/language-subtag-registry/language-subtag-registry
  ###
  @setUserFavLang: (tag) =>
    # If tag language is set manually
    if tag?
      if tag.length > 2
        throw new Error 'Tag language must be two characters. Use ledger.i18n.setLocale() if you want to set the region'
      @userFavLang = tag
    else
      @loadUserBrowserUiLang()
      @loadUserBrowserAcceptLangs()
      .then(() -> @setUserFavLangFromBrowserAcceptLanguages)
      .catch (err) -> l(err)
      .done()
      tag ?= @userFavLang || @browserUiLang
      @userFavLang = tag

    # set tag language to one of the store
    if ledger.storage.sync?
      ledger.storage.sync.set({i18n_userFavLocale: tag})
    else
      ledger.i18n.chromeStore.set({i18n_userFavLang: tag})
    @checkBoolUserFavLang()



  ###
    Load @userFavLang from syncStore or chromeStore

    @return [Promise]
  ###
  @loadUserFavLang: () =>
    deferred = Q.defer()

    if ledger.storage.sync?
      # Set @userFavLang from syncStore
      ledger.storage.sync.get('i18n_userFavLang', (r) =>
        if Array.isArray(r.i18n_userFavLang)
          r.i18n_userFavLang = r.i18n_userFavLang[0]
        @userFavLang = r.i18n_userFavLang
        deferred.resolve()
      )
    else
      # Set userFavLang from chromeStore
      @chromeStore.get('i18n_userFavLang', (r) =>
        if Array.isArray(r.i18n_userFavLang)
          r.i18n_userFavLang = r.i18n_userFavLang[0]
        @userFavLang = r.i18n_userFavLang
        deferred.resolve()
      )
    return deferred.promise


  ###
    Check if userFavLang is set into syncStore or chromeStore

    @return [Promise]
  ###
  @checkBoolUserFavLang: () =>
    deferred = Q.defer()

    if ledger.storage.sync?
      ledger.storage.sync.get 'i18n_userFavLang', (r) =>
        #l r.i18n_userFavLang
        if r.i18n_userFavLang isnt undefined
          @userFavLangSyncStoreIsSet = true
          deferred.resolve()
        else
          @userFavLangSyncStoreIsSet = false
          deferred.reject()
    else
      @chromeStore.get 'i18n_userFavLang', (r) =>
        #l r.i18n_userFavLang
        if r.i18n_userFavLang isnt undefined
          @userFavLangChromeStoreIsSet = true
          deferred.resolve()
        else
          l '@userFavLang is not set neither into synced Store or chrome store'
          @userFavLangChromeStoreIsSet = false
          deferred.reject()

    return deferred.promise



  ###
    Remove key 'i18n_userFavLang' from sync Store
  ###
  @removeUserFavLangSyncStore: () =>
    ledger.storage.sync.remove('i18n_userFavLang', l)
    @checkBoolUserFavLang()


  ###
    Remove key 'i18n_userFavLang' from chrome Store
  ###
  @removeUserFavLangChromeStore: () =>
    @chromeStore.remove('i18n_userFavLang', l)
    @checkBoolUserFavLang()



  # User Favorite Locale ####

  ###
    Set user locale (region)

    @param [String] tag Codified (BCP 47) language tag - Official list here : http://www.iana.org/assignments/language-subtag-registry/language-subtag-registry
  ###
  @setLocale: (tag) =>
    # If tag language is set manually
    if tag?
      if tag.length < 5
        throw new Error 'Tag language must be at least five characters. Use ledger.i18n.setUserFavLang() if you want to set the language without the region'
      if tag.substr(0, 2) isnt @userFavLang
        throw new Error 'You cannot set a locale which does not correspond to the user favorite language'
      @userFavLocale = tag
    else
      tag ?= @userFavLocale || @browserUiLang
      @userFavLocale = tag

    # set tag language to one of the store
    if ledger.storage.sync?
      ledger.storage.sync.set({i18n_userFavLocale: tag})
      @checkBoolLocale()
    else
      ledger.i18n.chromeStore.set({i18n_userFavLocale: tag})
      @checkBoolLocale()

    # Set the locale for Moment.js
    moment.locale(@userFavLocale.toLowerCase())



  ###
    Set and Get @userFavLocale from one of the store

    @return [Promise]
  ###
  @loadLocale: () =>
    deferred = Q.defer()
    if ledger.storage.sync?
      # Set userFavLocale from syncStore
      ledger.storage.sync.get('i18n_userFavLocale', (r) =>
        if Array.isArray(r.i18n_userFavLocale)
          r.i18n_userFavLocale = r.i18n_userFavLocale[0]
        @userFavLocale = r.i18n_userFavLocale
        deferred.resolve()
      )
    else
      # Set userFavLocale from chromeStore
      @chromeStore.get('i18n_userFavLocale', (r) =>
        if Array.isArray(r.i18n_userFavLocale)
          r.i18n_userFavLocale = r.i18n_userFavLocale[0]
        @userFavLocale = r.i18n_userFavLocale
        deferred.resolve()
      )
    return deferred.promise



  ###
    Check if @userFavLocale is set into syncStore or chromeStore

    @return [Promise]
  ###
  @checkBoolLocale: () =>
    deferred = Q.defer()
    if ledger.storage.sync?
      ledger.storage.sync.get 'i18n_userFavLocale', (r) =>
        #l r.i18n_userFavLocale
        if r.i18n_userFavLocale isnt undefined
          @userFavLocaleSyncStoreIsSet = true
          deferred.resolve()
        else
          @userFavLocaleSyncStoreIsSet = false
          deferred.reject()
    else
      @chromeStore.get 'i18n_userFavLocale', (r) =>
        #l r.i18n_userFavLocale
        if r.i18n_userFavLocale isnt undefined
          @userFavLocaleChromeStoreIsSet = true
          deferred.resolve()
        else
          @userFavLocaleChromeStoreIsSet = false
          l '@userFavLocale is not set neither into synced Store or chrome store'
          deferred.reject()

    return deferred.promise



  ###
    Remove key 'i18n_userFavLocale' from sync Store
  ###
  @removeLocaleSyncStore: () =>
    ledger.storage.sync.remove('i18n_userFavLocale', l)
    @checkBoolLocale()


  ###
    Remove key 'i18n_userFavLocale' from chrome Store
  ###
  @removeLocaleChromeStore: () =>
    @chromeStore.remove('i18n_userFavLocale', l)
    @checkBoolLocale()



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
  @t = (messageId) =>
    messageId = _.string.replace(messageId, '.', '_')
    res = @.translations[@userFavLang][messageId]['message']

    return res if res? and res.length > 0
    return messageId



  # Formatters ######

  ###
    Formats amounts with currency symbol

    @param [String] amount The amount to format
    @return [String] The formatted amount
  ###
  @formatAmount = (amount) ->

    options =
      style: "currency"
      currency: "AUD"
      currencyDisplay: "symbol"

    (amount).toLocaleString("en", options)


  ###
    Set the locale for Moment.js
  ###
  @setMomentLocale = () =>
    moment.locale(@userFavLocale.toLowerCase())


  ###
    Formats date and time

    @param [Date] dateTime The date and time to format
    @return [String] The formatted date and time
  ###
  @formatDateTime = (dateTime) ->
    moment(dateTime).format @t 'common.date_time_format'


  ###
    Formats date

    @param [Date] date The date to format
    @return [String] The formatted date
  ###
  @formatDate = (date) ->
    moment(date).format t 'common.date_format'


  ###
    Formats time

    @param [Date] time The time to format
    @return [String] The formatted time
  ###
  @formatTime = (time) ->
    moment(time).format t 'common.time_format'


@t = ledger.i18n.t