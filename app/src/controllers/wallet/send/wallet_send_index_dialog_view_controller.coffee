class @WalletSendIndexDialogViewController extends ledger.common.DialogViewController

  view:
    amountInput: '#amount_input'
    currencyContainer: '#currency_container'
    sendButton: '#send_button'
    totalLabel: '#total_label'
    counterValueTotalLabel: '#countervalue_total_label'
    errorContainer: '#error_container'
    receiverInput: '#receiver_input'
    dataInput: '#data_input'
    dataRow: '#data_row'
    openScannerButton: '#open_scanner_button'
    feesSelect: '#fees_select'
    accountsSelect: '#accounts_select'
    colorSquare: '#color_square'
    maxButton: '#max_button'
    customFeesRow: '#custom_fees_row'
    warning: '#warning'

  RefreshWalletInterval: 15 * 60 * 1000 # 15 Minutes

  onAfterRender: () ->
    super
    @view.dataRow.hide()
    if ledger.config.network.name == "bitcoin"
      _.defer =>
        ledger.api.WarningRestClient.getWarning().then((json) ->
          if json.message?
            @view.warning.text(json.message)
            @view.warning.show()
          if json.link?
            @view.link.on "click", open("json.link")
            @view.link.show()
        )
    @view.warning.show()
    # apply params
    if @params.amount?
      @view.amountInput.val @params.amount
    if @params.address?
      @view.receiverInput.val @params.address
    if @params.data? && @params.data.length > 0
      @view.dataInput.val @params.data
      @view.dataRow.show()
    @view.customFeesRow.hide()
    # configure view
    @view.amountInput.amountInput(ledger.preferences.instance.getBitcoinUnitMaximumDecimalDigitsCount())
    @view.errorContainer.hide()
    @_utxo = []
    @_updateFeesSelect()
    @_updateAccountsSelect()
    @_updateCurrentAccount()
    @_updateTotalLabel()
    @_listenEvents()
    @_ensureDatabaseUpToDate()
    @_updateSendButton()
    @_updateTotalLabel = _.debounce(@_updateTotalLabel.bind(this), 500)

  onShow: ->
    super
    @view.amountInput.focus()

  onDismiss: ->
    super
    clearTimeout(@_scheduledRefresh) if @_scheduledRefresh?


  cancel: ->
    Api.callback_cancel 'send_payment', t('wallet.send.errors.cancelled')
    @dismiss()

  send: ->
    nextError = @_nextFormError()
    if nextError?
      @view.errorContainer.show()
      @view.errorContainer.text nextError
    else
      @view.errorContainer.hide()

      pushDialogBlock = (fees) =>
        {utxo, fees} = @_computeAmount(ledger.Amount.fromSatoshi(fees).divide(1000))
        data = if (@_dataValue().length > 0) then @_dataValue() else undefined
        dialog = new WalletSendPreparingDialogViewController amount: @_transactionAmount(), address: @_receiverBitcoinAddress(), fees: fees, account: @_selectedAccount(), utxo: utxo, data: data
        @getDialog().push dialog

      {amount, fees} = @_computeAmount()
      # check transactions fees
#      if +fees > ledger.preferences.fees.MaxValue
#        # warn if wrong
#        dialog = new CommonDialogsConfirmationDialogViewController()
#        dialog.showsCancelButton = yes
#        dialog.restrainsDialogWidth = no
#        dialog.negativeText = _.str.sprintf(t('wallet.send.index.no_use'), ledger.formatters.formatValue(ledger.preferences.fees.MaxValue))
#        dialog.positiveLocalizableKey = 'common.yes'
#        dialog.message = _.str.sprintf(t('common.errors.fees_too_high'), ledger.formatters.formatValue(fees))
#        dialog.once 'click:positive', => pushDialogBlock(@view.feesSelect.val())
#        dialog.once 'click:negative', => pushDialogBlock(ledger.preferences.fees.MaxValue)
#        dialog.show()
#      else
#        # push next dialog
      pushDialogBlock(@view.feesSelect.val())

  max: ->
    feePerByte = ledger.Amount.fromSatoshi(@view.feesSelect.val()).divide(1000)
    utxo = @_utxo
    total = ledger.Amount.fromSatoshi(0)
    for output in utxo
      total = total.add(output.get('value'))
    {fees} = @_computeAmount(feePerByte, total)
    amount = total.subtract(fees)
    if amount.lte(0)
      amount = ledger.Amount.fromSatoshi(0)
    @view.amountInput.val ledger.formatters.fromValue(amount, -1, off)
    _.defer =>
      @_updateTotalLabel()
      @_updateExchangeValue()


  openScanner: ->
    dialog = new CommonDialogsQrcodeDialogViewController
    dialog.qrcodeCheckBlock = (data) =>
      if Bitcoin.Address.validate data
        return true
      params = ledger.managers.schemes.bitcoin.parseURI data
      return params?
    dialog.once 'qrcode', (event, data) =>
      if Bitcoin.Address.validate data
        params = {address: data}
      else
        params = ledger.managers.schemes.bitcoin.parseURI data
      if params?.amount?
        separator = ledger.number.getLocaleDecimalSeparator(ledger.preferences.instance.getLocale().replace('_', '-'))
        @view.amountInput.val(ledger.formatters.formatUnit(ledger.formatters.fromBtcToSatoshi(params.amount), ledger.preferences.instance.getBtcUnit()).replace(separator, '.'))
      @view.receiverInput.val params.address if params?.address?
      @_updateTotalLabel()
    dialog.show()

  _listenEvents: ->
    @view.amountInput.on 'keyup', =>
      _.defer =>
        @_updateTotalLabel()
        @_updateExchangeValue()
    @view.openScannerButton.on 'click', =>
      @openScanner()
    @view.customFeesRow.find('input').keypress (e) =>
      if (e.which < 48 || 57 < e.which)
        e.preventDefault()
    @view.customFeesRow.find('input').on 'keyup', =>
      _.defer =>
        @view.feesSelect.find(":selected").attr('value', parseInt(@view.customFeesRow.find('input').val()) * 1000)
        @_updateTotalLabel()
    @view.feesSelect.on 'change', =>
      if @view.feesSelect.find(":selected").text() is t("wallet.send.index.custom_fees")
        @view.customFeesRow.show()
      else
        @view.customFeesRow.hide()
      @_updateTotalLabel()
    @view.accountsSelect.on 'change', =>
      @_updateCurrentAccount()
      @_updateTotalLabel()
    ledger.app.on 'wallet:operations:changed', =>
      @_updateUtxo()
      @_updateTotalLabel()

  _updateCustomFees: ->

  _receiverBitcoinAddress: ->
    _.str.trim(@view.receiverInput.val())

  _transactionAmount: ->
    ledger.formatters.fromValueToSatoshi(_.str.trim(@view.amountInput.val()))

  _dataValue: ->
    @view.dataInput.val()

  _isDataValid: ->
    s = @_dataValue()
    s.match(/^[a-f0-9]+$/i) != null && s.length % 2 == 0 && s.length <= 160

  _nextFormError: ->
    # check amount
    if @_transactionAmount().length == 0 or not ledger.Amount.fromSatoshi(@_transactionAmount()).gt(0)
      return t 'common.errors.invalid_amount'
    else if not ledger.bitcoin.checkAddress @_receiverBitcoinAddress() || @_receiverBitcoinAddress().startsWith("z")
      return _.str.sprintf(t('common.errors.invalid_receiver_address'), ledger.config.network.name)
    else if @_dataValue().length > 0 && not @_isDataValid()
      return t 'common.errors.invalid_op_return_data'
    else if ledger.Amount.fromSatoshi(@view.feesSelect.val()).divide(1000).lt(1) && @view.customFeesRow.is(':visible')
      return t 'wallet.send.index.satoshi_per_byte_too_low'
    undefined

  _updateFeesSelect: ->
    @view.feesSelect.empty()
    for id in _.sortBy(_.keys(ledger.preferences.defaults.Coin.fees), (id) -> ledger.preferences.defaults.Coin.fees[id].value).reverse()
      fee = ledger.preferences.defaults.Coin.fees[id]
      text = t(fee.localization)
      node = $("<option></option>").text(text).attr('value', ledger.tasks.FeesComputationTask.instance.getFeesForLevelId(fee.value.toString()).value)
      if fee.value == ledger.preferences.instance.getMiningFee()
        node.attr 'selected', true
      @view.feesSelect.append node
    node = $("<option></option>").text(t("wallet.send.index.custom_fees")).attr('value', 0)
    @view.feesSelect.append node

  _updateTotalLabel: ->
    {amount, fees} = @_computeAmount()
    @view.totalLabel.text ledger.formatters.formatValue(amount) + ' ' + _.str.sprintf(t('wallet.send.index.transaction_fees_text'), ledger.formatters.formatValue(fees))
    counterValueFee = ledger.converters.satoshiToCurrencyFormatted(fees)
    if parseInt(ledger.converters.satoshiToCurrency(fees, "USD")) >= 1
      counterValueFee = '<span class="bold-invalid-text">' + counterValueFee + '</span>'
    @view.counterValueTotalLabel.html ledger.converters.satoshiToCurrencyFormatted(amount) + ' ' + _.str.sprintf(t('wallet.send.index.transaction_fees_text'), counterValueFee)

  _updateExchangeValue: ->
    value = ledger.Amount.fromSatoshi(@_transactionAmount())
    if ledger.preferences.instance.isCurrencyActive()
      if value.toString() != @view.currencyContainer.attr('data-countervalue')
        @view.currencyContainer.removeAttr 'data-countervalue'
        @view.currencyContainer.empty()
        @view.currencyContainer.attr 'data-countervalue', value
    else
      @view.currencyContainer.hide()

  _updateAccountsSelect: ->
    accounts = Account.displayableAccounts()
    for account in accounts
      option = $('<option></option>').text(account.name + ' (' + ledger.formatters.formatValue(account.balance) + ')').val(account.index)
      option.attr('selected', true) if @params.account_id? and account.index is +@params.account_id
      @view.accountsSelect.append option
    @_updateUtxo()

  _updateCurrentAccount: ->
    @_updateUtxo()
    @_updateColorSquare()

  _updateUtxo: ->
    @_utxo = _(@_selectedAccount().getUtxo()).sortBy (o) -> o.get('transaction').get('confirmations')

  _updateColorSquare: ->
    @view.colorSquare.css('color', @_selectedAccount().get('color'))

  _selectedAccount: ->
    Account.find(index: parseInt(@view.accountsSelect.val())).first()

  _computeAmount: (feePerByte = ledger.Amount.fromSatoshi(@view.feesSelect.val()).divide(1000), desiredAmount = undefined) ->
    account = @_selectedAccount()
    desiredAmount ?= ledger.Amount.fromSatoshi(@_transactionAmount())
    if desiredAmount.lte(0)
      return total: ledger.Amount.fromSatoshi(0), amount: ledger.Amount.fromSatoshi(0), fees: ledger.Amount.fromSatoshi(0), utxo: [], size: 0
    utxo = @_utxo
    compute = (target) =>
      selectedUtxo = []
      total = ledger.Amount.fromSatoshi(0)
      for output in utxo when total.lt(target)
        selectedUtxo.push output
        total = total.add(output.get('value'))
      estimatedSize = ledger.bitcoin.estimateTransactionSize(selectedUtxo.length, 2).max # For now always consider we need a change output
      if (@_dataValue().length > 0)
        estimatedSize += @_dataValue().length / 2 + 4 + 1
      if ledger.config.network.handleFeePerByte
        fees = feePerByte.multiply(estimatedSize)
      else
        fees = feePerByte.multiply(1000).multiply(Math.floor(estimatedSize / 1000) + (if estimatedSize % 1000 != 0 then 1 else 0))
      if desiredAmount.gt(0) and total.lt(desiredAmount.add(fees)) and selectedUtxo.length is utxo.length
        # Not enough funds
        total: total, amount: desiredAmount.add(fees), fees: fees, utxo: selectedUtxo, size: estimatedSize
      else if desiredAmount.gt(0) and total.lt(desiredAmount.add(fees))
        compute(desiredAmount.add(fees))
      else
        total: total, amount: desiredAmount.add(fees), fees: fees, utxo: selectedUtxo, size: estimatedSize
    compute(desiredAmount)

  _ensureDatabaseUpToDate: ->
    task = ledger.tasks.WalletLayoutRecoveryTask.instance
    task.getLastSynchronizationStatus().then (status) =>
      d = ledger.defer()
      if task.isRunning() or _.isEmpty(status) or status is 'failure'
        @_updateSendButton(yes)
        task.startIfNeccessary()
        task.once 'done', =>
          d.resolve()
        task.once 'fatal_error', =>
          d.reject(new Error("Fatal error during sync"))
      else
        d.resolve()
      d.promise
    .fail (er) =>
      return unless @isShown()
      e er
      @_scheduledRefresh = _.delay(@_ensureDatabaseUpToDate.bind(this), 30 * 1000)
      throw er
    .then () =>
      ledger.tasks.FeesComputationTask.instance.update().then =>
        @_updateSendButton(no)
        @_updateFeesSelect()
        @_updateTotalLabel()
        return unless @isShown()
    return

  _updateSendButton: (syncing = ledger.tasks.WalletLayoutRecoveryTask.instance.isRunning()) ->
    if syncing
      @view.sendButton.addClass('disabled')
      @view.sendButton.text(t('wallet.send.index.syncing'))
    else
      @view.sendButton.removeClass('disabled')
      @view.sendButton.text(t('common.send'))
