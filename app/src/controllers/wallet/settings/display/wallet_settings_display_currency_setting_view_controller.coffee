class @WalletSettingsDisplayCurrencySettingViewController extends WalletSettingsSettingViewController

  renderSelector: "#currency_table_container"
  view:
    switchContainer: "#switch_container"
    exchangeRateRow: "#exchange_rate_row"
    currenciesSelect: "#currencies_select"

  onAfterRender: ->
    super
    # add switch
    @view.switch = new ledger.widgets.Switch(@view.switchContainer)
    @view.switch.on 'isOn', => @_handleSwitchChanged(on)
    @view.switch.on 'isOff', => @_handleSwitchChanged(off)

    # update currencies
    ledger.tasks.TickerTask.instance.getCacheAsync (data) =>
      @view.currenciesSelect.empty()
      for id in _.sortBy(_.keys(data), (id) -> data[id].name)
        node = $("<option></option>").text(data[id].name + ' - ' + data[id].ticker + ' (' + data[id].symbol + ')').attr('value', id)
        @view.currenciesSelect.append node

  _handleSwitchChanged: (state) ->
    # todo update settings + ui
    @view.exchangeRateRow.toggleClass 'disabled'