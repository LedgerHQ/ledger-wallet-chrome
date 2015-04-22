class @WalletSettingsBitcoinBlockchainSettingViewController extends WalletSettingsSettingViewController

  renderSelector: "#blockchain_table_container"
  view:
    blockchainSelect: "#blockchain_select"

  onAfterRender: ->
    super
    @_updateExplorer()
    @_listenEvents()

  _updateExplorer: ->
    @view.blockchainSelect.empty()
    for id in _.keys(ledger.preferences.defaults.Bitcoin.explorers)
      node = $("<option></option>").text(ledger.preferences.defaults.Bitcoin.explorers[id].name).attr('value', id)
      if id == ledger.preferences.instance.getBlockchainExplorer()
        node.attr 'selected', true
      @view.blockchainSelect.append node

  _listenEvents: ->
    @view.blockchainSelect.on 'change', =>
      ledger.preferences.instance.setBlockchainExplorer(@view.blockchainSelect.val())