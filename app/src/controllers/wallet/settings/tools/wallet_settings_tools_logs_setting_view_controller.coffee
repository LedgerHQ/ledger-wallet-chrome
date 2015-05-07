class @WalletSettingsToolsLogsSettingViewController extends WalletSettingsSettingViewController

  renderSelector: "#logs_table_container"
  view:
    switchContainer: "#switch_container"
    exportLogsRow: "#export_logs_row"

  onAfterRender: ->
    super
    # add switch
    @view.switch = new ledger.widgets.Switch(@view.switchContainer)
    @_listenEvents()
    @_updateSwitchState()
    @_updateExportLogsRowAlpha()

  exportLogs: ->
    ledger.utils.Logger.downloadLogsWithLink()

  _updateSwitchState: ->
      # update switch state
    @view.switch.setOn(ledger.preferences.instance.isLogActive())

  _listenEvents: ->
    # switch state
    @view.switch.on 'isOn', => @_handleSwitchChanged(on)
    @view.switch.on 'isOff', => @_handleSwitchChanged(off)

  _handleSwitchChanged: (state) ->
    # save in prefs
    ledger.preferences.instance.setLogActive(state)

    # update UI
    @_updateExportLogsRowAlpha()

  _updateExportLogsRowAlpha: ->
    if @view.switch.isOn() then @view.exportLogsRow.removeClass 'disabled' else @view.exportLogsRow.addClass 'disabled'