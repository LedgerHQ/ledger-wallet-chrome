class @WalletSettingsDisplayUnitsSettingViewController extends WalletSettingsSettingViewController

  renderSelector: "#units_table_container"
  view:
    segmentedControlContainer: "#segmented_control_container"

  onAfterRender: ->
    super
    # add segmented control
    @view.segmentedControl = new ledger.widgets.SegmentedControl(@view.segmentedControlContainer, ledger.widgets.SegmentedControl.Styles.Small)
    @_updateUnits()
    @_listenEvents()

  _updateUnits: ->
    # add options
    indexToSelect = -1
    @view.segmentedControl.removeAllActions()
    for id, index in _.keys(ledger.preferences.defaults.Display.units)
      @view.segmentedControl.addAction ledger.preferences.defaults.Display.units[id].symbol
      if ledger.preferences.defaults.Display.units[id].symbol == ledger.preferences.instance.getBtcUnit()
        indexToSelect = index

    # select current option
    @view.segmentedControl.setSelectedIndex(indexToSelect) if indexToSelect != -1

  _listenEvents: ->
    @view.segmentedControl.on 'selection', (event, data) =>
      symbol = ledger.preferences.defaults.Display.units[_.keys(ledger.preferences.defaults.Display.units)[data.index]].symbol
      ledger.preferences.instance.setBtcUnit(symbol)