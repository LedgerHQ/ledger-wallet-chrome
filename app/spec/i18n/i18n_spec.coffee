describe "Internationalization and Localization -", ->
  i18n = ledger.i18n
  chromeStore = new ledger.storage.ChromeStore('i18n')

  describe "Test setFavLangByUI() - ", ->

    it "should change the language", ->
      i18n.setFavLangByUI('en')
      expect(i18n.favLang.memoryValue).toBe('en')

    it "should sync the language to chrome store", (done) ->
      i18n.setFavLangByUI('en')
      res = ''
      call = () ->
        d = Q.defer()
        chromeStore.get '__i18n_favLang', (r) ->
          if Array.isArray(r.__i18n_favLang)
            r.i18n_favLang = r.__i18n_favLang[0]
          res = r.__i18n_favLang
          d.resolve(res)
        return d.promise
      call()
      .then (res) ->
        expect(res).toBe('en')
        done()
      .done()

    it "should sync the language to synced store", (done) ->
      i18n.setFavLangByUI('fr')
      res = ''
      call = () ->
        d = Q.defer()
        ledger.storage.sync.get '__i18n_favLang', (r) ->
          if Array.isArray(r.__i18n_favLang)
            r.i18n_favLang = r.__i18n_favLang[0]
          res = r.__i18n_favLang
          d.resolve(res)
        return d.promise
      call()
      .then (res) ->
        expect(res).toBe('fr')
        done()
      .done()


  describe "Test setLocaleByUI() - ", ->

    it "should change the locale", (done) ->
      i18n.setLocaleByUI('en-GB')
      .then ->
        expect(i18n.favLocale.memoryValue).toBe('en-GB')
      .then ->
        expect(moment.locale()).toBe('en-gb')
        done()
      .done()

    it "should sync the locale to chrome store", (done) ->
      i18n.setLocaleByUI('zh-tw')
      res = ''
      call = () ->
        d = Q.defer()
        chromeStore.get '__i18n_favLocale', (r) ->
          if Array.isArray(r.__i18n_favLocale)
            r.__i18n_favLang = r.__i18n_favLocale[0]
          res = r.__i18n_favLocale
          d.resolve(res)
        return d.promise
      call()
      .then (res) ->
        expect(res).toBe('zh-tw')
        done()
      .done()

    it "should sync the locale to synced store", (done) ->
      i18n.setLocaleByUI('fr-CA')
      res = ''
      call = () ->
        d = Q.defer()
        ledger.storage.sync.get '__i18n_favLocale', (r) ->
          if Array.isArray(r.__i18n_favLocale)
            r.i18n_favLocale = r.__i18n_favLocale[0]
          res = r.__i18n_favLocale
          d.resolve(res)
        return d.promise
      call()
      .then (res) ->
        expect(res).toBe('fr-CA')
        done()
      .done()


  # This test can be launch only one time - Need app restart
  describe "Check lang and locale memory and stores values after full initialization", ->

    originalTimeout = jasmine.DEFAULT_TIMEOUT_INTERVAL
    jasmine.DEFAULT_TIMEOUT_INTERVAL = 50000

    beforeEach (done) ->
      ledger.storage.sync.clear ->
        chrome.storage.local.clear -> done()
    #originalTimeout = jasmine.DEFAULT_TIMEOUT_INTERVAL
    #jasmine.DEFAULT_TIMEOUT_INTERVAL = 10000


    it "should set two chars tag lang and four chars tag locale", (done) ->
      i18n.loadUserBrowserAcceptLangs = () ->
        i18n.browserAcceptLanguages = ['be', 'fr-CA', 'zh-tw', 'fr']
        Q()
      i18n.init ->
        expect(i18n.favLang.memoryValue).toBe('fr')
        expect(i18n.favLang.chromeStoreValue).toBe('fr')
        expect(i18n.favLang.syncStoreValue).toBe('fr')
        expect(i18n.favLocale.memoryValue).toBe('fr-CA')
        expect(i18n.favLocale.chromeStoreValue).toBe('fr-CA')
        expect(i18n.favLocale.syncStoreValue).toBe('fr-CA')
        done()

    # Should be 'fr' if it is the first supported language in the browserAcceptLanguages array
    it "should set two chars tag lang and locale", (done) ->
      i18n.loadUserBrowserAcceptLangs = () ->
        i18n.browserAcceptLanguages = ['zh', 'fr', 'en-GB', 'it']
        Q()
      i18n.init ->
        expect(i18n.favLang.memoryValue).toBe('fr')
        expect(i18n.favLang.chromeStoreValue).toBe('fr')
        expect(i18n.favLang.syncStoreValue).toBe('fr')
        expect(i18n.favLocale.memoryValue).toBe('fr')
        expect(i18n.favLocale.chromeStoreValue).toBe('fr')
        expect(i18n.favLocale.syncStoreValue).toBe('fr')
        done()

    it "should fallback to browser UI lang - chrome.i18n.getUILanguage()", (done) ->
      i18n.loadUserBrowserAcceptLangs = () ->
        i18n.browserAcceptLanguages = ['dfr', 'huj', 'jla', 'dede', 'lp']
        Q()
      i18n.init ->
        expect(i18n.favLang.memoryValue).toBe(chrome.i18n.getUILanguage())
        expect(i18n.favLang.chromeStoreValue).toBe(chrome.i18n.getUILanguage())
        expect(i18n.favLang.syncStoreValue).toBe(chrome.i18n.getUILanguage())
        expect(i18n.favLocale.memoryValue).toBe(chrome.i18n.getUILanguage())
        expect(i18n.favLocale.chromeStoreValue).toBe(chrome.i18n.getUILanguage())
        expect(i18n.favLocale.syncStoreValue).toBe(chrome.i18n.getUILanguage())
        done()

    it "should have sync store set", (done) ->
      i18n.loadUserBrowserAcceptLangs = () ->
        i18n.browserAcceptLanguages = ['be', 'fr-CA', 'zh-tw', 'fr']
        Q()
      i18n.init ->
        expect(i18n.favLang.syncStoreIsSet).toBe(true)
        expect(i18n.favLocale.syncStoreIsSet).toBe(true)
        done()


    afterEach (done) ->
      ledger.storage.sync.clear ->
        chrome.storage.local.clear -> done()
      i18n.favLang =
        memoryValue: undefined
        syncStoreValue: undefined
        chromeStoreValue: undefined
        syncStoreIsSet: undefined
        chromeStoreIsSet: undefined
        storesAreSync: undefined

      i18n.favLocale =
        memoryValue: undefined
        syncStoreValue: undefined
        chromeStoreValue: undefined
        syncStoreIsSet: undefined
        chromeStoreIsSet: undefined
        storesAreSync: undefined

    jasmine.DEFAULT_TIMEOUT_INTERVAL = originalTimeout
