class ledger.i18n

  # syncStore instance
  @syncStore: undefined
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


  @init: (cb) =>
    #@syncStore = new ledger.storage.SyncedStore('i18n')

    @chromeStore = new ledger.storage.ChromeStore('i18n')

    @Languages = Object.keys(ledger.i18n.Languages)

    for tag in @Languages
      @loadTrad(tag)

    # Manage text translation
    @setBoolUserFavLangChromeStore()
    .then(
      () =>

        if @userFavLangChromeStoreIsSet
          l 'Language: store is set'
          @loadUserFavLangFromChromeStore()
          .catch (err) -> l(err)
          .done()

        else
          l 'Language: store is not set'
          @setUserBrowserUiLang()
          @fetchUserBrowserAcceptLangs()
          .then(() -> @setUserFavLangFromBrowserAcceptLanguages)
          .then(@setUserFavLangIntoChromeStore)
          .then(@setBoolUserFavLangChromeStore)
          .catch (err) -> l(err)
          .done()
    )
    .catch (err) -> l(err)
    .done()


    # Manage date, time and currency converters
    @setBoolLocaleChromeStore()
    .then(
      () =>

        if @userFavLocaleChromeStoreIsSet
          l 'Locale: store is set'
          @loadLocaleFromChromeStore()
          .then(@setMomentLocale)
        else
          l 'Locale: store is not set'
          @setLocaleIntoChromeStore()
          .then(@setBoolLocaleChromeStore)
          @setMomentLocale()
    )
    .catch (err) -> l(err)
    .done()

    @onPulledSyncStore()

    cb()



  ###
    Set user language of his Chrome browser UI version into @browserUiLang
  ###
  @setUserBrowserUiLang: () ->
    ledger.i18n.browserUiLang = chrome.i18n.getUILanguage()


  ###
    Get user favorite languages with regions set in his Chrome browser preferences and store it in @acceptLanguages variable - Async call

    @return [Promise] promise Promise containing the user favorite languages with regions
  ###
  @fetchUserBrowserAcceptLangs: () =>
    deferred = Q.defer()
    chrome.i18n.getAcceptLanguages (requestedLocales) =>
      @browserAcceptLanguages = requestedLocales
      deferred.resolve(requestedLocales)

    return deferred.promise


  ###
    Set user favorite language via the app UI

    @param [String] tag Codified (BCP 47) language tag - Official list here : http://www.iana.org/assignments/language-subtag-registry/language-subtag-registry
    @return [String] @userFavLang The favorite user language
  ###
  @setUserFavLangByUI: (tag) ->
    if tag.length > 2
      throw new Error 'Tag language must be two characters. Use ledger.i18n.setLocaleByUI() if you want to set the region'
    ledger.i18n.userFavLang = tag
    @setUserFavLangIntoChromeStore()


  ###
    Set user locale via the app UI

    @param [String] tag Codified (BCP 47) language tag - Official list here : http://www.iana.org/assignments/language-subtag-registry/language-subtag-registry
    @return [String] @userFavLang The favorite user language
  ###
  @setLocaleByUI: (tag) =>
    if tag.length < 5
      throw new Error 'Tag language must be at least five characters. Use ledger.i18n.setUserFavLangByUI() if you want to set the language without the region'

    if tag.substr(0, 2) isnt @userFavLang
      throw new Error 'You cannot set a locale which does not correspond to the user favorite language'

    @userFavLocale = tag

    @setLocaleIntoChromeStore()
    @setMomentLocale()



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


  ###
    SyncedStore
  ###
  @onPulledSyncStore: () ->
    try
      ledger.storage.sync.on('pulled', (r) ->
        l 'pulllled!'
        l r
      )
    catch err
      l err


  ###
    Set user favorite language into chromeStore (Local Storage)
  ###
  @setUserFavLangIntoChromeStore: (tag) =>
    tag ?= @userFavLang || @browserUiLang
    @userFavLang = tag

    ledger.i18n.chromeStore.set({i18n_userFavLang: tag})
    @setBoolUserFavLangChromeStore()

   

  ###
    Set user locale into chromeStore (Local Storage)
  ###
  @setLocaleIntoChromeStore: (tag) =>
    tag ?= @userFavLocale || @browserUiLang
    @userFavLocale = tag

    ledger.i18n.chromeStore.set({i18n_userFavLocale: tag})
    @setBoolLocaleChromeStore()



  ###
    Set and Get @userFavLang from chromeStore (Local Storage)

    @return [Promise]
  ###
  @loadUserFavLangFromChromeStore: () =>
    deferred = Q.defer()
    # Set userFavLang from chromeStore
    @chromeStore.get('i18n_userFavLang', (r) ->
      if Array.isArray(r.i18n_userFavLang)
        r.i18n_userFavLang = r.i18n_userFavLang[0]
      ledger.i18n.userFavLang = r.i18n_userFavLang
      deferred.resolve(r)
    )
    return deferred.promise


  ###
    Set and Get @userFavLocale from chromeStore (Local Storage)

    @return [Promise]
  ###
  @loadLocaleFromChromeStore: () =>
    deferred = Q.defer()
    # Set userFavLocale from chromeStore
    @chromeStore.get('i18n_userFavLocale', (r) ->
      if Array.isArray(r.i18n_userFavLocale)
        r.i18n_userFavLocale = r.i18n_userFavLocale[0]
      ledger.i18n.userFavLocale = r.i18n_userFavLocale
      deferred.resolve(r)
    )
    return deferred.promise


  ###
    Check if userFavLang is set into chromeStore (Local Storage)
  ###
  @setBoolUserFavLangChromeStore: () =>
    deferred = Q.defer()
    @chromeStore.get('i18n_userFavLang', (r) =>
      #l r.i18n_userFavLang
      if r.i18n_userFavLang isnt undefined
        @userFavLangChromeStoreIsSet = true
      else
        @userFavLangChromeStoreIsSet = false
      deferred.resolve(r)
    )
    return deferred.promise


  ###
    Check if userFavLocale is set into chromeStore (Local Storage)
  ###
  @setBoolLocaleChromeStore: () =>
    deferred = Q.defer()
    @chromeStore.get('i18n_userFavLocale', (r) =>
      #l r.i18n_userFavLocale
      if r.i18n_userFavLocale isnt undefined
        @userFavLocaleChromeStoreIsSet = true
      else
        @userFavLocaleChromeStoreIsSet = false
      deferred.resolve(r)
    )
    return deferred.promise  

    
  ###
    Remove key 'i18n_userFavLang' from chrome Store
  ###
  @removeUserFavLangChromeStore: () =>
    @chromeStore.remove('i18n_userFavLang', l)
    @setBoolUserFavLangChromeStore()


  ###
    Remove key 'i18n_userFavLocale' from chrome Store
  ###
  @removeLocaleChromeStore: () =>
    @chromeStore.remove('i18n_userFavLocale', l)
    @setBoolLocaleChromeStore()  


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