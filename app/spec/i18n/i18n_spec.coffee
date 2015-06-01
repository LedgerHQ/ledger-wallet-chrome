describe "Internationalization and Localization -", ->
  i18n = ledger.i18n
  chromeStore = {}
  originalTimeout = jasmine.DEFAULT_TIMEOUT_INTERVAL

  beforeAll ->
    jasmine.DEFAULT_TIMEOUT_INTERVAL = 5000

  beforeEach ->
    ledger.storage.sync = new ledger.storage.MemoryStore('i18n')
    chromeStore = new ledger.storage.ChromeStore('i18n')


  describe "Test setFavLangByUI() - ", ->

    it "should change the language", ->
      i18n.setFavLangByUI('en')
      expect(i18n.favLang.memoryValue).toBe('en')

    it "should sync the language to chrome store", (done) ->
      i18n.setFavLangByUI('en')
      res = ''
      call = () ->
        d = ledger.defer()
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
        d = ledger.defer()
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
        d = ledger.defer()
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
        d = ledger.defer()
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

    it "should set two chars tag lang and four chars tag locale", (done) ->
      spyOn(i18n, 'loadUserBrowserAcceptLangs').and.callFake ->
        d = ledger.defer()
        i18n.browserAcceptLanguages = ['be', 'fr-CA', 'zh-tw', 'fr']
        d.resolve().promise
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
      spyOn(i18n, 'loadUserBrowserAcceptLangs').and.callFake ->
        d = ledger.defer()
        i18n.browserAcceptLanguages = ['zh', 'fr', 'en-GB', 'it']
        d.resolve().promise
      i18n.init ->
        expect(i18n.favLang.memoryValue).toBe('fr')
        expect(i18n.favLang.chromeStoreValue).toBe('fr')
        expect(i18n.favLang.syncStoreValue).toBe('fr')
        expect(i18n.favLocale.memoryValue).toBe('fr')
        expect(i18n.favLocale.chromeStoreValue).toBe('fr')
        expect(i18n.favLocale.syncStoreValue).toBe('fr')
        done()

    it "should fallback to browser UI lang - chrome.i18n.getUILanguage()", (done) ->
      spyOn(i18n, 'loadUserBrowserAcceptLangs').and.callFake ->
        d = ledger.defer()
        i18n.browserAcceptLanguages = ['dfr', 'huj', 'jla', 'dede', 'lp']
        d.resolve().promise
      i18n.init ->
        expect(i18n.favLang.memoryValue).toBe(chrome.i18n.getUILanguage())
        expect(i18n.favLang.chromeStoreValue).toBe(chrome.i18n.getUILanguage())
        expect(i18n.favLang.syncStoreValue).toBe(chrome.i18n.getUILanguage())
        expect(i18n.favLocale.memoryValue).toBe(chrome.i18n.getUILanguage())
        expect(i18n.favLocale.chromeStoreValue).toBe(chrome.i18n.getUILanguage())
        expect(i18n.favLocale.syncStoreValue).toBe(chrome.i18n.getUILanguage())
        done()

    it "should have sync store set", (done) ->
      spyOn(i18n, 'loadUserBrowserAcceptLangs').and.callFake ->
        d = ledger.defer()
        i18n.browserAcceptLanguages = ['be', 'fr-CA', 'zh-tw', 'fr']
        d.resolve().promise
      i18n.init ->
        expect(i18n.favLang.syncStoreIsSet).toBe(true)
        expect(i18n.favLocale.syncStoreIsSet).toBe(true)
        done()


    afterEach ->
      chrome.storage.local.clear()

    jasmine.DEFAULT_TIMEOUT_INTERVAL = originalTimeout
