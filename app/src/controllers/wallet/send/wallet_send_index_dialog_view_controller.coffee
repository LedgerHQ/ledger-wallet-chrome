class @WalletSendIndexDialogViewController extends DialogViewController

  view:
    amountInput: '#amount_input'
    sendButton: '#send_button'
    totalInput: '#total_input'
    errorContainer: '#error_container'
    receiverInput: '#receiver_input'
    openScannerButton: '#open_scanner_button'

  onAfterRender: () ->
    super
    if @params.amount?
      @view.amountInput.val @params.amount
    if @params.address?
      @view.receiverInput.val @params.address
    @view.amountInput.amountInput(ledger.preferences.instance.getBitcoinUnitMaximumDecimalDigitsCount())
    @view.errorContainer.hide()
    do @_updateTotalInput
    do @_listenEvents

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
      dialog = new WalletSendPreparingDialogViewController amount: @_transactionAmount(), address: @_receiverBitcoinAddress()
      @getDialog().push dialog

  openScanner: ->
    dialog = new CommonDialogsQrcodeDialogViewController
    dialog.qrcodeCheckBlock = (data) =>
      params = ledger.managers.schemes.bitcoin.parseURI data
      return params?
    dialog.once 'qrcode', (event, data) =>
      params = ledger.managers.schemes.bitcoin.parseURI data
      @view.amountInput.val params.amount if params?.amount?
      @view.receiverInput.val params.address if params?.address?
      @_updateTotalInput()
    dialog.show()

  _listenEvents: ->
    @view.amountInput.on 'keydown', =>
      _.defer =>
        @_updateTotalInput yes
    @view.openScannerButton.on 'click', =>
      @openScanner()

  _receiverBitcoinAddress: ->
    _.str.trim(@view.receiverInput.val())

  _transactionAmount: ->
    ledger.formatters.fromValueToSatoshi(_.str.trim(@view.amountInput.val()))

  _nextFormError: ->
    # check amount
    if @_transactionAmount().length == 0 or not ledger.wallet.Value.from(@_transactionAmount()).gt(0)
      return t 'common.errors.invalid_amount'
    else if not Bitcoin.Address.validate @_receiverBitcoinAddress()
      return t 'common.errors.invalid_receiver_address'
    undefined

  _updateTotalInput: ->
    fees = ledger.preferences.instance.getMiningFee()
    val = ledger.wallet.Value.from(@_transactionAmount()).add(fees).toString()
    @view.totalInput.text ledger.formatters.formatValue(val) + ' ' + _.str.sprintf(t('wallet.send.index.transaction_fees_text'), ledger.formatters.formatValue(fees))