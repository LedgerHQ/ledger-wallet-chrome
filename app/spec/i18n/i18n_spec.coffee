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

    it "should change the language", (done) ->
      i18n.setFavLangByUI('en')
      .then ->
        expect(i18n.favLang.memoryValue).toBe('en')
        done()

    it "should sync the language to chrome store", (done) ->
      i18n.setFavLangByUI('en')
      .then ->
        res = ''
        chromeStore.get ['__i18n_favLang'], (r) ->
          if Array.isArray(r.__i18n_favLang) then res = r.__i18n_favLang[0] else res = r.__i18n_favLang
          expect(res).toBe('en')
          done()

    it "should sync the language to synced store", (done) ->
      i18n.setFavLangByUI('fr')
      .then ->
        res = ''
        ledger.storage.sync.get '__i18n_favLang', (r) ->
          if Array.isArray(r.__i18n_favLang) then res = r.__i18n_favLang[0] else res = r.__i18n_favLang
          expect(res).toBe('fr')
          done()


  describe "Test setLocaleByUI() - ", ->

    it "should change the locale", (done) ->
      i18n.setLocaleByUI('en-GB')
      .then ->
        expect(i18n.favLocale.memoryValue).toBe('en-GB')
        expect(moment.locale()).toBe('en-gb')
        done()

    it "should sync the locale to chrome store", (done) ->
      i18n.setLocaleByUI('zh-tw')
      .then ->
        res = ''
        chromeStore.get ['__i18n_favLocale'], (r) ->
          if Array.isArray(r.__i18n_favLocale) then res = r.__i18n_favLocale[0] else res = r.__i18n_favLocale
          expect(res).toBe('zh-tw')
          done()

    it "should sync the locale to synced store", (done) ->
      i18n.setLocaleByUI('fr-CA')
      .then ->
        res = ''
        ledger.storage.sync.get ['__i18n_favLocale'], (r) ->
          if Array.isArray(r.__i18n_favLocale) then res = r.__i18n_favLocale[0] else res = r.__i18n_favLocale
          expect(res).toBe('fr-CA')
          done()


  describe "Check values after full init (chromeStore + syncStore)", ->

    beforeEach ->
      chromeStore.remove ['__i18n_favLang']
      chromeStore.remove ['__i18n_favLocale']
      ledger.storage.sync.remove ['__i18n_favLang']
      ledger.storage.sync.remove ['__i18n_favLocale']

    it "should set two chars tag lang and four chars tag locale", (done) ->
      spyOn(i18n, 'initBrowserAcceptLanguages').and.callFake ->
        i18n.browserAcceptLanguages = ['be', 'fr-CA', 'zh-tw', 'fr']
        ledger.defer().resolve().promise
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
      spyOn(i18n, 'initBrowserAcceptLanguages').and.callFake ->
        i18n.browserAcceptLanguages = ['zh', 'fr', 'en-GB', 'it']
        ledger.defer().resolve().promise
      i18n.init ->
        expect(i18n.favLang.memoryValue).toBe('fr')
        expect(i18n.favLang.chromeStoreValue).toBe('fr')
        expect(i18n.favLang.syncStoreValue).toBe('fr')
        expect(i18n.favLocale.memoryValue).toBe('fr')
        expect(i18n.favLocale.chromeStoreValue).toBe('fr')
        expect(i18n.favLocale.syncStoreValue).toBe('fr')
        done()

    it "should fallback to browser UI lang - chrome.i18n.getUILanguage()", (done) ->
      spyOn(i18n, 'initBrowserAcceptLanguages').and.callFake ->
        i18n.browserAcceptLanguages = ['dfr', 'huj', 'jla', 'dede', 'lp']
        ledger.defer().resolve().promise
      i18n.init ->
        expect(i18n.favLang.memoryValue).toBe(chrome.i18n.getUILanguage())
        expect(i18n.favLang.chromeStoreValue).toBe(chrome.i18n.getUILanguage())
        expect(i18n.favLang.syncStoreValue).toBe(chrome.i18n.getUILanguage())
        expect(i18n.favLocale.memoryValue).toBe(chrome.i18n.getUILanguage())
        expect(i18n.favLocale.chromeStoreValue).toBe(chrome.i18n.getUILanguage())
        expect(i18n.favLocale.syncStoreValue).toBe(chrome.i18n.getUILanguage())
        done()

    it "should have sync store set", (done) ->
      spyOn(i18n, 'initBrowserAcceptLanguages').and.callFake ->
        i18n.browserAcceptLanguages = ['be', 'fr-CA', 'zh-tw', 'fr']
        ledger.defer().resolve().promise
      i18n.init ->
        expect(i18n.favLang.syncStoreIsSet).toBe(true)
        expect(i18n.favLocale.syncStoreIsSet).toBe(true)
        done()


    afterEach ->
      chrome.storage.local.clear()

    jasmine.DEFAULT_TIMEOUT_INTERVAL = originalTimeout
