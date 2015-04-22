class @WalletSettingsBitcoinConfirmationsSettingViewController extends WalletSettingsSettingViewController

  renderSelector: "#confirmations_table_container"
  view:
    segmentedControlContainer: "#segmented_control_container"

  onAfterRender: ->
    super
    @view.segmentedControl = new ledger.widgets.SegmentedControl(@view.segmentedControlContainer, ledger.widgets.SegmentedControl.Styles.Small)
    @view.segmentedControl.on 'selection', (event, data) => @_handleSegmentedControlClick(data.index)
    for id in _.keys(ledger.preferences.defaults.Bitcoin.confirmations)
      @view.segmentedControl.addAction ledger.preferences.defaults.Bitcoin.confirmations[id]

  _handleSegmentedControlClick: (index) ->
    confirmations = _.keys(ledger.preferences.defaults.Bitcoin.confirmations)
    l ledger.preferences.defaults.Bitcoin.confirmations[confirmations[index]]