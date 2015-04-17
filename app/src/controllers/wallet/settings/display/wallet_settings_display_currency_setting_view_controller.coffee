class @WalletSettingsDisplayCurrencySettingViewController extends WalletSettingsSettingViewController

  renderSelector: "#currency_table_container"
  view:
    switchContainer: "#switch_container"
    exchangeRateRow: "#exchange_rate_row"

  onAfterRender: ->
    super
    # add switch
    @view.switch = new ledger.widgets.Switch(@view.switchContainer)
    @view.switch.on 'isOn', => @_handleSwitchChanged(on)
    @view.switch.on 'isOff', => @_handleSwitchChanged(off)

    # update ui from settings
    @view.exchangeRateRow.addClass 'disabled'

  _handleSwitchChanged: (state) ->
    # todo update settings + ui
    @view.exchangeRateRow.toggleClass 'disabled'