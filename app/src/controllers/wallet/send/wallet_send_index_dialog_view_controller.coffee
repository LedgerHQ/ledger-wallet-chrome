class @WalletSendIndexDialogViewController extends ledger.common.DialogViewController

  view:
    amountInput: '#amount_input'
    sendButton: '#send_button'
    totalLabel: '#total_label'
    errorContainer: '#error_container'
    receiverInput: '#receiver_input'
    openScannerButton: '#open_scanner_button'
    feesSelect: '#fees_select'

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
        dialog = new WalletSendPreparingDialogViewController amount: @_transactionAmount(), address: @_receiverBitcoinAddress(), fees: fees
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
        @view.amountInput.val(ledger.formatters.formatUnit(ledger.formatters.fromBtcToSatoshi(params.amount), ledger.preferences.instance.getBtcUnit()))
      @view.receiverInput.val params.address if params?.address?
      @_updateTotalLabel()
    dialog.show()

  _listenEvents: ->
    @view.amountInput.on 'keydown', =>
      _.defer => @_updateTotalLabel()
    @view.openScannerButton.on 'click', =>
      @openScanner()
    @view.feesSelect.on 'change', =>
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

  _updateFeesSelectAndTotalLabel: ->
    @_updateFeesSelect()
    @_updateTotalLabel()

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
    fees = @view.feesSelect.val()
    val = ledger.Amount.fromSatoshi(@_transactionAmount()).add(fees).toString()
    @view.totalLabel.text ledger.formatters.formatValue(val) + ' ' + _.str.sprintf(t('wallet.send.index.transaction_fees_text'), ledger.formatters.formatValue(fees))