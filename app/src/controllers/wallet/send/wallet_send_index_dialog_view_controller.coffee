class @WalletSendIndexDialogViewController extends ledger.common.DialogViewController

  view:
    amountInput: '#amount_input'
    currencyContainer: '#currency_container'
    sendButton: '#send_button'
    totalLabel: '#total_label'
    errorContainer: '#error_container'
    receiverInput: '#receiver_input'
    openScannerButton: '#open_scanner_button'
    feesSelect: '#fees_select'
    accountsSelect: '#accounts_select'
    colorSquare: '#color_square'

  onAfterRender: () ->
    super

    # apply params
    if @params.amount?
      @view.amountInput.val @params.amount
    if @params.address?
      @view.receiverInput.val @params.address

    # configure view
    @view.amountInput.amountInput(ledger.preferences.instance.getBitcoinUnitMaximumDecimalDigitsCount())
    @view.errorContainer.hide()
    @_updateFeesSelect()
    @_updateAccountsSelect()
    @_updateCurrentAccount()
    @_updateTotalLabel()
    @_listenEvents()

  onShow: ->
    super
    @view.amountInput.focus()

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
        dialog = new WalletSendPreparingDialogViewController amount: @_transactionAmount(), address: @_receiverBitcoinAddress(), fees: fees, account: @_selectedAccount()
        @getDialog().push dialog

      # check transactions fees
      if +@view.feesSelect.val() > ledger.preferences.fees.MaxValue
        # warn if wrong
        dialog = new CommonDialogsConfirmationDialogViewController()
        dialog.showsCancelButton = yes
        dialog.restrainsDialogWidth = no
        dialog.negativeText = _.str.sprintf(t('wallet.send.index.no_use'), ledger.formatters.formatValue(ledger.preferences.fees.MaxValue))
        dialog.positiveLocalizableKey = 'common.yes'
        dialog.message = _.str.sprintf(t('common.errors.fees_too_high'), ledger.formatters.formatValue(@view.feesSelect.val()))
        dialog.once 'click:positive', => pushDialogBlock(@view.feesSelect.val())
        dialog.once 'click:negative', => pushDialogBlock(ledger.preferences.fees.MaxValue)
        dialog.show()
      else
        # push next dialog
        pushDialogBlock(@view.feesSelect.val())

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
    @view.feesSelect.on 'change', =>
      @_updateTotalLabel()
    @view.accountsSelect.on 'change', =>
      @_updateCurrentAccount()
      @_updateTotalLabel()
    ledger.app.on 'wallet:operations:changed', =>
      @_updateTotalLabel()

  _receiverBitcoinAddress: ->
    _.str.trim(@view.receiverInput.val())

  _transactionAmount: ->
    ledger.formatters.fromValueToSatoshi(_.str.trim(@view.amountInput.val()))

  _nextFormError: ->
    # check amount
    if @_transactionAmount().length == 0 or not ledger.Amount.fromSatoshi(@_transactionAmount()).gt(0)
      return t 'common.errors.invalid_amount'
    else if not Bitcoin.Address.validate @_receiverBitcoinAddress()
      return t 'common.errors.invalid_receiver_address'
    undefined

  _updateFeesSelect: ->
    @view.feesSelect.empty()
    for id in _.sortBy(_.keys(ledger.preferences.defaults.Bitcoin.fees), (id) -> ledger.preferences.defaults.Bitcoin.fees[id].value).reverse()
      fee = ledger.preferences.defaults.Bitcoin.fees[id]
      text = t(fee.localization)
      node = $("<option></option>").text(text).attr('value', ledger.tasks.FeesComputationTask.instance.getFeesForLevelId(fee.value.toString()).value)
      if fee.value == ledger.preferences.instance.getMiningFee()
        node.attr 'selected', true
      @view.feesSelect.append node

  _updateTotalLabel: ->
    {amount, fees} = @_computeAmount()
    @view.totalLabel.text ledger.formatters.formatValue(amount) + ' ' + _.str.sprintf(t('wallet.send.index.transaction_fees_text'), ledger.formatters.formatValue(fees))

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

  _updateCurrentAccount: ->
    @_updateColorSquare()
    l "Time to utxo"

  _updateColorSquare: ->
    @view.colorSquare.css('color', @_selectedAccount().get('color'))

  _selectedAccount: ->
    Account.find(index: parseInt(@view.accountsSelect.val())).first()

  _computeAmount: ->
    account = @_selectedAccount()
    desiredAmount = ledger.Amount.fromSatoshi(@_transactionAmount())
    feePerByte = ledger.Amount.fromSatoshi(@view.feesSelect.val()).divide(1000)
    compute = (target) =>
      utxo = account.getUtxo()
      selectedUtxo = []
      total = ledger.Amount.fromSatoshi(0)
      for output in utxo when total.lt(target)
        selectedUtxo.push output
        total = total.add(output.get('value'))
      estimatedSize = ledger.bitcoin.estimateTransactionSize(selectedUtxo.length, 2).max # For now always consider we need a change output
      fees = feePerByte.multiply(estimatedSize)
      if desiredAmount.gt(0) and total.lt(desiredAmount.add(fees)) and selectedUtxo.length is utxo.length
        # Not enough funds
        total: total, amount: desiredAmount.add(fees), fees: fees, utxo: selectedUtxo, size: estimatedSize
      else if desiredAmount.gt(0) and total.lt(desiredAmount.add(fees))
        compute(desiredAmount.add(fees))
      else
        total: total, amount: desiredAmount.add(fees), fees: fees, utxo: selectedUtxo, size: estimatedSize
    compute(desiredAmount)