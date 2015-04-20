class @WalletSettingsDisplayUnitsSettingViewController extends WalletSettingsSettingViewController

  renderSelector: "#units_table_container"
  view:
    segmentedControlContainer: "#segmented_control_container"

  onAfterRender: ->
    super
    @view.segmentedControl = new ledger.widgets.SegmentedControl(@view.segmentedControlContainer, ledger.widgets.SegmentedControl.Styles.Small)
    @view.segmentedControl.on 'selection', (event, data) => @_handleSegmentedControlClick(data.index)
    @view.segmentedControl.addAction '1'
    @view.segmentedControl.addAction '2'
    @view.segmentedControl.addAction '3'

  _handleSegmentedControlClick: (index) ->
    l index