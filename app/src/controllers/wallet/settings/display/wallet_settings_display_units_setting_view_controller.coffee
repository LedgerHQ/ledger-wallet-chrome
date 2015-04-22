class @WalletSettingsDisplayUnitsSettingViewController extends WalletSettingsSettingViewController

  renderSelector: "#units_table_container"
  view:
    segmentedControlContainer: "#segmented_control_container"

  onAfterRender: ->
    super
    @view.segmentedControl = new ledger.widgets.SegmentedControl(@view.segmentedControlContainer, ledger.widgets.SegmentedControl.Styles.Small)
    @view.segmentedControl.on 'selection', (event, data) => @_handleSegmentedControlClick(data.index)
    for id in _.keys(ledger.preferences.defaults.Display.units)
      @view.segmentedControl.addAction ledger.preferences.defaults.Display.units[id].symbol

  _handleSegmentedControlClick: (index) ->
    l ledger.preferences.defaults.Display.units[_.keys(ledger.preferences.defaults.Display.units)[index]].symbol