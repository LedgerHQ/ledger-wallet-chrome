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
    @_updateCurrencies()
    @_updateSwitchState()
    @_updateExchangeRowAlpha()
    @_listenEvents()

  _updateExchangeRowAlpha: ->
    if @view.switch.isOn() then @view.exchangeRateRow.removeClass 'disabled' else @view.exchangeRateRow.addClass 'disabled'

  _updateCurrencies: ->
    # update currencies
    ledger.tasks.TickerTask.instance.getCacheAsync (data) =>
      @view.currenciesSelect.empty()
      for id in _.sortBy(_.keys(data), (id) -> data[id].name)
        node = $("<option></option>").text(data[id].name + ' - ' + data[id].ticker + ' (' + data[id].symbol + ')').attr('value', id)
        if data[id].ticker == ledger.preferences.instance.getCurrency()
          node.attr 'selected', true
        @view.currenciesSelect.append node

  _updateSwitchState: ->
    # update switch state
    @view.switch.setOn(ledger.preferences.instance.isCurrencyActive())

  _listenEvents: ->
    @view.switch.on 'isOn', => @_handleSwitchChanged(on)
    @view.switch.on 'isOff', => @_handleSwitchChanged(off)
    @view.currenciesSelect.on 'change', =>
      ledger.preferences.instance.setCurrency(@view.currenciesSelect.val())

  _handleSwitchChanged: (state) ->
    # save in prefs
    ledger.preferences.instance.setCurrencyActive(state)

    # update UI
    @_updateExchangeRowAlpha()