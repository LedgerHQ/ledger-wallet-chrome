describe "Internationalization and Localization -", ->
  i18n = ledger.i18n
  chromeStore = new ledger.storage.ChromeStore('i18n')

  it "should change the language", ->
    i18n.setFavLangByUI('es')
    expect(i18n.favLang.memoryValue).toBe('es')

  it "should sync the language to chrome store", (done) ->
    i18n.setFavLangByUI('en')
    res = ''
    call = () ->
      d = Q.defer()
      chromeStore.get 'i18n_favLang', (r) ->
        if Array.isArray(r.i18n_favLang)
          r.i18n_favLang = r.i18n_favLang[0]
        res = r.i18n_favLang
        d.resolve(res)
      return d.promise

    call()
    .then (res) ->
      expect(res).toBe('en')
      done()
    .done()


  it "should sync the language to synced store", ->
    i18n.setFavLangByUI('fr')
    res = ''
    ledger.storage.sync.get 'i18n_favLang', (r) ->
      if Array.isArray(r.i18n_favLang)
        r.i18n_favLang = r.i18n_favLang[0]
      #l 'syncstore', r.i18n_favLang
      res = r.i18n_favLang
      deferred.resolve()
    expect(res).toBe('fr')


  fit "should set two chars tag lang and locale", (done) ->
    ledger.storage.sync.clear()
    i18n.loadUserBrowserAcceptLangs = () -> #
    i18n.browserAcceptLanguages = ['be', 'en', 'zh-tw', 'fr']

    i18n.init(done) ->
      expect(i18n.favLang.memoryValue).toBe('en')
      expect(i18n.favLocale.memoryValue).toBe('en')
      done()


  it "should set two chars tag lang and four chars tag locale", ->
    ledger.storage.sync.clear()
    i18n.browserAcceptLanguages = ['be', 'en-GB', 'zh-tw', 'fr']
    i18n.init()
    expect(i18n.favLang.memoryValue).toBe('en')
    expect(i18n.favLocale.memoryValue).toBe('en-GB')