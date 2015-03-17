class ledger.i18n

  # Contain all the translation files
  @translations: {}
  # User favorite language or fallback on first accepted language
  @userFavLang: undefined
  # User favorite language, only set via the UI
  @_userFavLangByUI: undefined
  # Languages + regions preferences of the user's Chrome browser
  @browserAcceptLanguages: undefined
  # UI language of the user's Chrome browser
  @browserUiLang: undefined
  # Supported languages by the app (when translation is done)
  @Languages: {}

  @syncStore: undefined
  @chromeStore: undefined



  @init: (cb) =>
    #@syncStore = new ledger.storage.SyncedStore('i18n')
    #@chromeStore = new ledger.storage.ChromeStore('i18n')

    @fetchUserBrowserUiLang()
    @fetchUserBrowserAcceptLangs()
    .then(@setUserFavLang)

    @Languages = Object.keys(ledger.i18n.Languages)

    for tag in @Languages
      @loadTrad(tag)

    cb()



  ###
    Get user favorite language based on the Chrome browser version and store it in @browserUiLang variable
  ###
  @fetchUserBrowserUiLang: () ->
    ledger.i18n.browserUiLang = chrome.i18n.getUILanguage()
    return ledger.i18n.browserUiLang


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

    @param [String] tag Codified language tag - cf. BCP 47 recommendation, composed by the IETF/IANA RFC 5646 and RFC 4647 - Official list here : http://www.iana.org/assignments/language-subtag-registry/language-subtag-registry
    @return [String] @userFavLang The favorite user language
  ###
  @setUserFavLangByUI: (tag) ->
    ledger.i18n._userFavLangByUI = tag
    @setUserFavLang()
    # Return @userFavLang and not @_userFavLangByUI - It allows us to check if @setUserFavLang() is working well
    return @userFavLang


  ###
    Set user favorite language by checking multiple hierarchical sources

    # implicit param containing browserAcceptLanguages is passed via the return promise of @fetchUserBrowserAcceptLangs() into the init function
  ###
  @setUserFavLang: () =>

    #l('0')
    #ledger.i18n.chromeStore.set({'i18n_favUserLang': ledger.i18n.userFavLang}, () -> l('done'))
    #l('1')

    if @_userFavLangByUI isnt undefined
      l('langUI')
      ledger.i18n.userFavLang = @_userFavLangByUI
      #else if @syncStore.get() isnt undefined
      #ledger.i18n.userFavLang = @syncStore.get()
    else if @chromeStore isnt undefined
      l('chromeStore')
      # Last used user language
      ledger.i18n.userFavLang = @chromeStore.get()
    else if @browserAcceptLanguages isnt undefined
      l('browserAcceptLanguages')
      # Select language tag without region
      i = 0
      for str in ledger.i18n.browserAcceptLanguages
        if ledger.i18n.browserAcceptLanguages[i].length > 2
          i++
          ledger.i18n.userFavLang = ledger.i18n.browserAcceptLanguages[i]

      # TODO - better way to do things. Augment name translation folder with region and create fallback to lang only. So it will supports localized translation by default
      # It also allow to normalize the API. Ex: @formatDateTime() like to have lang+region
      # API with region tag by default then automatic fallback will be nice!
    else
      l('browserUiLang')
      ledger.i18n.userFavLang = ledger.i18n.browserUiLang

    return ledger.i18n.userFavLang


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

    #l(ledger.i18n.userFavLang)
    res = ledger.i18n.translations[ledger.i18n.userFavLang][messageId]['message']

    return res if res? and res.length > 0
    return messageId


  ###
    Detect Intl EcmaScript API support
  ###
  @detectIntlSupport: () ->
    if !(window.Intl && typeof window.Intl == "object")
      console.log("Update your browser!")


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
    Formats date and time

    @param [Date] dateTime The date-time to format
    @return [String] The formatted date-time
  ###
  @formatDateTime = (dateTime) ->
    @detectIntlSupport()

    options =
      weekday: "short"
      year: "numeric"
      month: "2-digit"
      day: "2-digit"
      hour: "2-digit"
      minute: "2-digit"

    dateTime.toLocaleDateString(ledger.i18n.userFavLang, options)
    # toLocaleTimeString()


@t = ledger.i18n.t