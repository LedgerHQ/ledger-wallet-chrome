class @WalletSettingsBitcoinConfirmationsSettingViewController extends WalletSettingsSettingViewController

  renderSelector: "#confirmations_table_container"
  view:
    segmentedControlContainer: "#segmented_control_container"
  _confirmations: []

  onAfterRender: ->
    super
    @view.segmentedControl = new ledger.widgets.SegmentedControl(@view.segmentedControlContainer, ledger.widgets.SegmentedControl.Styles.Small)
    @view.segmentedControl.on 'selection', (event, data) => @_handleSegmentedControlClick(data.index)
    for id in _.sortBy(_.keys(ledger.preferences.defaults.Bitcoin.confirmations), (id) => ledger.preferences.defaults.Bitcoin.confirmations[id])
      @view.segmentedControl.addAction ledger.preferences.defaults.Bitcoin.confirmations[id]
      @_confirmations.push id

  _handleSegmentedControlClick: (index) ->
    l ledger.preferences.defaults.Bitcoin.confirmations[@_confirmations[index]]