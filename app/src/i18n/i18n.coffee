class ledger.i18n

  # Contain all the translation files
  @translations: {}
  # User favorite language
  @userFavLang: undefined
  # User favorite language and region
  @userFavLangAndRegion: undefined
  # Languages + regions tags that represent the user's Chrome browser preferences
  @browserAcceptLanguages: undefined
  # Language tag that depends on the browser UI language
  @browserUiLang: undefined
  # Supported languages by the app (when translation is done)
  @Languages: {}

  @syncStore: undefined
  # chromeStore instance
  @chromeStore: undefined



  @init: (cb) =>
    #@syncStore = new ledger.storage.SyncedStore('i18n')
    @chromeStore = new ledger.storage.ChromeStore('i18n')

    @Languages = Object.keys(ledger.i18n.Languages)

    for tag in @Languages
      @loadTrad(tag)

    @setUserBrowserUiLang()
    @fetchUserBrowserAcceptLangs()
    .then(@userFavLangFromChromeStore)
    .then(@setUserFavLangIntoChromeStore)
    .then(@setMomentLocale)
    .catch (err) -> l(err)
    .done()

    ###
      if userFavLag is set into chrome store
        @setUserBrowserUiLang()
        @fetchUserBrowserAcceptLangs()
        .then(@userFavLangFromChromeStore)
        .then(@setMomentLocale)

      else
        @setUserBrowserUiLang()
        @fetchUserBrowserAcceptLangs()
        .then(@setUserFavLangIntoChromeStore)
        .then(@setMomentLocale)
    ###

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
  @fetchUserBrowserAcceptLangs: () ->
    deferred = Q.defer()
    chrome.i18n.getAcceptLanguages (requestedLocales) ->
      ledger.i18n.browserAcceptLanguages = requestedLocales
      deferred.resolve(requestedLocales)

    return deferred.promise


  ###
    Set user favorite language via the app UI

    @param [String] tag Codified (BCP 47) language tag - Official list here : http://www.iana.org/assignments/language-subtag-registry/language-subtag-registry
    @return [String] @userFavLang The favorite user language
  ###
  @setUserFavLangByUI: (tag) ->
    if tag.length > 2
      throw new Error 'Tag language must be two characters. Use ledger.i18n.setUserFavLangAndRegionByUI() if you want to set the region'
    ledger.i18n.userFavLang = tag
    @setUserFavLangIntoChromeStore()


  ###
    Set user favorite language via the app UI

    @param [String] tag Codified language tag - cf. BCP 47 recommendation, composed by the IETF/IANA RFC 5646 and RFC 4647 - Official list here : http://www.iana.org/assignments/language-subtag-registry/language-subtag-registry
    @return [String] @userFavLang The favorite user language
  ###
  @setUserFavLangAndRegionByUI: (tag) ->
    if tag.length < 5
      throw new Error 'Tag language must be at least five characters. Use ledger.i18n.setUserFavLangByUI() if you want to set the language without the region'
    ledger.i18n.userFavLangAndRegion = tag
    @setUserFavLangAndRegionIntoChromeStore()


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
        ledger.i18n.userFavLangAndRegion = ledger.i18n.browserAcceptLanguages[i]


  ###
    Set user favorite language into chromeStore (Local Storage)
  ###
  @setUserFavLangIntoChromeStore: (tag) =>
    tag ?= @userFavLang

    ledger.i18n.chromeStore.set({i18n_userFavLang: tag})

    ###
    if @userFavLang isnt undefined
      l(@userFavLang)
      ledger.i18n.chromeStore.set({i18n_userFavLang: tag})
    else if @browserUiLang isnt undefined
      l @browserUiLang, 'setUserFavLangIntoChromeStore'
      ledger.i18n.chromeStore.set({i18n_userFavLang: ledger.i18n.browserUiLang})
    else if @browserAcceptLanguages isnt undefined
      @setUserFavLangFromBrowserAcceptLanguages()
      ledger.i18n.chromeStore.set({i18n_userFavLang: tag})
      l @browserAcceptLanguages
    else
      l('en')
      ledger.i18n.chromeStore.set({i18n_userFavLang: 'en', i18n_userFavLangAndRegion: 'en-US'})
    ###

  ###
    Set user favorite language with region into chromeStore (Local Storage)
  ###
  @setUserFavLangAndRegionIntoChromeStore: () =>
    if @userFavLangAndRegion isnt undefined
      l(@userFavLangAndRegion)
      ledger.i18n.chromeStore.set({i18n_userFavLangAndRegion: ledger.i18n.userFavLangAndRegion})
    else if @browserUiLang isnt undefined
      l @browserUiLang, 'setUserFavLangIntoChromeStore'
      ledger.i18n.chromeStore.set({i18n_userFavLangAndRegion: ledger.i18n.browserUiLang})
    else if @browserAcceptLanguages isnt undefined
      @setUserFavLangFromBrowserAcceptLanguages()
      ledger.i18n.chromeStore.set({i18n_userFavLangAndRegion: ledger.i18n.userFavLangAndRegion})
      l @browserAcceptLanguages
    else
      l('en')
      ledger.i18n.chromeStore.set({i18n_userFavLangAndRegion: 'en-US'})


  ###
    Set and Get @userFavLang from chromeStore (Local Storage)
  ###
  @userFavLangFromChromeStore: () =>
    deferred = Q.defer()
    # Set userFavLang from chromeStore
    @chromeStore.get('i18n_userFavLang', (r) ->
      ledger.i18n.userFavLang = r.i18n_userFavLang
      deferred.resolve(r)
    )
    return @userFavLang


  ###
    Check if userFavLang is set into chromeStore (Local Storage)
  ###
  @checkUserFavLangChromeStore: () =>
    deferred = Q.defer()
    # Set userFavLang from chromeStore
    @chromeStore.get('i18n_userFavLang', (r) ->
      l r.i18n_userFavLang
      #l (r.i18n_userFavLang is null or undefined)
      deferred.resolve(r)
    )
    return @userFavLang



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
  @t = (messageId) ->
    messageId = _.string.replace(messageId, '.', '_')

    res = ledger.i18n.translations[ledger.i18n.userFavLang][messageId]['message']

    return res if res? and res.length > 0
    return messageId


  ###
    Formats amounts with currency symbol

    @param [String] amount The amount to format
    @return [String] The formatted amount
  ###
  @formatAmount = (amount) ->
    @detectIntlSupport()

    options =
      style: "currency"
      currency: "AUD"
      currencyDisplay: "symbol"

    (amount).toLocaleString("en", options)


  ###
    Set the locale for Moment.js
  ###
  @setMomentLocale = () ->
    moment.locale(@userFavLangAndRegion)


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