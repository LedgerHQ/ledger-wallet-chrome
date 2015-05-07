class @WalletSettingsDisplayLanguageSettingViewController extends WalletSettingsSettingViewController

  renderSelector: "#language_table_container"
  view:
    languageSelect: "#language_select"
    regionSelect: "#region_select"

  onAfterRender: ->
    super
    @_updateLanguages()
    @_updateRegions()
    @_listenEvents()

  _updateLanguages: ->
    # add all languages
    @view.languageSelect.empty()
    for id in _.sortBy(_.keys(ledger.preferences.defaults.Display.languages), (id) -> ledger.preferences.defaults.Display.languages[id])
      node = $("<option></option>").text(ledger.preferences.defaults.Display.languages[id]).attr('value', id)
      if id == ledger.preferences.instance.getLanguage()
        node.attr 'selected', true
      @view.languageSelect.append node

  _updateRegions: (fromPreferences = true) ->
    # add corresponding regions
    languageCode = @view.languageSelect.val()
    @view.regionSelect.empty()
    for id in _.sortBy(_.keys(ledger.preferences.defaults.Display.regions), (id) -> ledger.preferences.defaults.Display.regions[id])
      continue if not _.str.startsWith(id, languageCode)
      node = $("<option></option>").text(ledger.preferences.defaults.Display.regions[id]).attr('value', id)
      if (fromPreferences == true and id == ledger.preferences.instance.getLocale()) or (fromPreferences == false and id == ledger.i18n.mostAcceptedLanguage())
        node.attr 'selected', true
      @view.regionSelect.append node

  _listenEvents: ->
    @view.languageSelect.on 'change', =>
      # set language in preferences
      ledger.preferences.instance.setLanguage(@view.languageSelect.val())
      @_updateRegions(false)
      # set region in preferences
      ledger.preferences.instance.setLocale(@view.regionSelect.val())
    @view.regionSelect.on 'change', =>
      # set region in preferences
      ledger.preferences.instance.setLocale(@view.regionSelect.val())