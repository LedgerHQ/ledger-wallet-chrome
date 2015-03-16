class ledger.i18n

  @userSetLocale: undefined
  @localeFileData: undefined
  @acceptLanguages: []
  @Languages: {}

  ###
  getLang = (cb) ->
    chrome.i18n.getAcceptLanguages (languages) ->
      l(languages)
      @acceptLanguages = languages
      cb?()
      null
  ###

  ###
    Get the locale in Synced_Store
  ###
  ###
  @getLocale = (lang, getLang) ->

    ledger.app.on('wallet:initializing', @getLocale)

    #acceptLanguages = []

    #l(getLang)
    #ledger.i18n.getLang()

    #locale = ledger.storage.sync.get('_i18n_' + lang)
    l(@acceptLanguages[0])
    return @acceptLanguages[0] unless locale?
  ###

  @returnCb: () =>
    #locale = ledger.storage.sync.get('_i18n_' + lang)
    l(@acceptLanguages[0])



  @getLocale: (locale, cb) ->

    ledger.app.on('wallet:initializing', @getLocale)

    chrome.i18n.getAcceptLanguages (languages) ->
      #l(languages)
      @acceptLanguages = languages
      cb?()

    l(@acceptLanguages[0])
    return @acceptLanguages[0] unless locale?




  # Translate a message id to a localized text
  #
  # @param [String] messageId Unique identifier of the message
  # @return [String] localized message
  #
  @t = (messageId) ->
    locale = ledger.i18n.getLocale('en', @returnCb)
    l(locale)
    url = '/_locales/' + locale + '/messages.json'

    res = $.ajax({
      dataType: "json",
      async: false,
      url: url,
      #data: data,
      success: (data) ->
        message = _.string.replace(messageId, '.', '_')
        @localeFileData = data
        return data + '.' + message
    })

    return res if res? and res.length > 0
    return messageId


@t = ledger.i18n.t

# ledger.i18n.loadLocale()