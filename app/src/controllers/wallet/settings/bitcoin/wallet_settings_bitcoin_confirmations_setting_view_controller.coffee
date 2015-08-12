class @WalletSettingsBitcoinConfirmationsSettingViewController extends WalletSettingsSettingViewController

  renderSelector: "#confirmations_table_container"
  view:
    segmentedControlContainer: "#segmented_control_container"

  onAfterRender: ->
    super
    @view.segmentedControl = new ledger.widgets.SegmentedControl(@view.segmentedControlContainer, ledger.widgets.SegmentedControl.Styles.Small)
    @_updateConfirmations()
    @_listenEvents()

  _updateConfirmations: ->
    # add all confirmations
    indexToSelect = -1
    @view.segmentedControl.removeAllActions()
    for id, index in _.keys(ledger.preferences.defaults.Bitcoin.confirmations)
      @view.segmentedControl.addAction ledger.preferences.defaults.Bitcoin.confirmations[id]
      if ledger.preferences.defaults.Bitcoin.confirmations[id] == ledger.preferences.instance.getConfirmationsCount()
        indexToSelect = index

    # select current option
    @view.segmentedControl.setSelectedIndex(indexToSelect) if indexToSelect != -1

  _listenEvents: ->
    @view.segmentedControl.on 'selection', (event, data) =>
      confirmations = _.keys(ledger.preferences.defaults.Bitcoin.confirmations)
      count = ledger.preferences.defaults.Bitcoin.confirmations[confirmations[data.index]]
      ledger.preferences.instance.setConfirmationsCount(count)
