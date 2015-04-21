class @WalletSettingsBitcoinBlockchainSettingViewController extends WalletSettingsSettingViewController

  renderSelector: "#blockchain_table_container"
  view:
    blockchainSelect: "#blockchain_select"

  onAfterRender: ->
    super
    for id in _.sortBy(_.keys(ledger.preferences.defaults.Bitcoin.explorers), (id) -> ledger.preferences.defaults.Bitcoin.explorers[id].name)
      node = $("<option></option>").text(ledger.preferences.defaults.Bitcoin.explorers[id].name).attr('value', id)
      @view.blockchainSelect.append node