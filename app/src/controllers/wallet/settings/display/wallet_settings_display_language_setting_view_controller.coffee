class @WalletSettingsDisplayLanguageSettingViewController extends WalletSettingsSettingViewController

  renderSelector: "#language_table_container"
  view:
    languageSelect: "#language_select"
    regionSelect: "#region_select"

  onAfterRender: ->
    super
    for id in _.sortBy(_.keys(ledger.preferences.defaults.Display.languages), (id) -> ledger.preferences.defaults.Display.languages[id])
      node = $("<option></option>").text(ledger.preferences.defaults.Display.languages[id]).attr('value', id)
      @view.languageSelect.append node
    for id in _.sortBy(_.keys(ledger.preferences.defaults.Display.regions), (id) -> ledger.preferences.defaults.Display.regions[id])
      node = $("<option></option>").text(ledger.preferences.defaults.Display.regions[id]).attr('value', id)
      @view.regionSelect.append node