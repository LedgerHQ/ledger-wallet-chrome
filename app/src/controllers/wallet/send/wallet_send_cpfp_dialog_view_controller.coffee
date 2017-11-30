class @WalletSendCpfpDialogViewController extends ledger.common.DialogViewController

  view:
    feesPerByte: '#fees_per_byte'
    check: '#check'
    message: '#message'
    feesPerByte: '#fees_per_byte'
    sendButton: '#send_button'
    totalLabel: '#total_label'
    counterValueTotalLabel: '#countervalue_total_label'
    feesValidation: '#fees_validation'



  initialize: () ->
    super
    @operation = @params.operation
    @account = @params.account
    @feesPerByte = ledger.tasks.FeesComputationTask.instance.getFeesForNumberOfBlocks(1) / 1000
    @transaction = @params.transaction
    @amount = ledger.formatters.formatValue(ledger.Amount.fromSatoshi(10000))
    @address = @params.account.getWalletAccount().getCurrentPublicAddress()
    @fees = @transaction.fees
    @countervalue = ledger.converters.satoshiToCurrencyFormatted(@fees)


  onShow: () ->
    super
    @view.feesPerByte.focus()

  onAfterRender: () ->
    super
    @view.feesValidation.hide()
    @_checkFees()
    @view.message.text(t('wallet.cpfp.message'))
    @view.check.text(t('wallet.cpfp.check'))
    @_updateTotalLabel(@fees, @countervalue)
    @view.feesPerByte.keypress (e) =>
      if (e.which < 48 || 57 < e.which || @view.feesPerByte.val() > 99999)
        e.preventDefault()
    @view.feesPerByte.on('paste', (e) =>
      e.preventDefault()
    )
    @view.feesPerByte.on 'keyup', _.debounce(
        @_checkFees
    ,50)


  _checkFees: ->
    @view.sendButton.addClass('disabled')
    ledger.bitcoin.cpfp.createTransaction(@account, @operation.get("hash"), ledger.Amount.fromSatoshi(@view.feesPerByte.val()))
    .then((transaction) =>
      @view.check.text(t('wallet.cpfp.check'))
      @view.check.removeClass('red')
      @view.sendButton.removeClass('disabled')
      @view.feesPerByte.removeClass('red')
      @transaction = transaction
      @fees = @transaction.fees
      @feesPerByte = @fees.add(@transaction.unconfirmed.fees).divide(@transaction.size)
      if (@feesPerByte.toSatoshiNumber() <= @transaction.unconfirmed.fees.divide(@transaction.unconfirmed.size).toSatoshiNumber())
        throw ledger.errors.new(ledger.errors.FeesTooLowCpfp, '', transaction)
      if (@feesPerByte.toSatoshiNumber() >= ledger.tasks.FeesComputationTask.instance.getFeesForNumberOfBlocks(1) / 1000)
        @view.feesValidation.text(t('wallet.cpfp.valid_fees'))
        @view.feesValidation.removeClass('red')
        @view.feesValidation.show()
      else
        @view.feesValidation.text(t('wallet.cpfp.low_fees'))
        @view.feesValidation.addClass('red')
        @view.feesValidation.show()
      @countervalue = ledger.converters.satoshiToCurrencyFormatted(@fees)
      @_updateTotalLabel(@fees, @countervalue)
    ).catch((err) =>
      @view.feesValidation.hide()
      @view.sendButton.addClass('disabled')
      @view.feesPerByte.addClass('red')
      @view.check.text(err.localizedMessage())
      @view.check.addClass('red')
      @fees = ledger.Amount.fromSatoshi(@view.feesPerByte.val()).multiply(@transaction.size)
      @countervalue = ledger.converters.satoshiToCurrencyFormatted(@fees)
      @_updateTotalLabel(@fees, @countervalue)
    )


  onDismiss: ->
    super
    clearTimeout(@_scheduledRefresh) if @_scheduledRefresh?

  cancel: ->
    Api.callback_cancel 'send_payment', t('wallet.send.errors.cancelled')
    @dismiss()

  send: ->
    preparingDialog = new WalletSendPreparingDialogViewController amount: 10000, address: @account.getWalletAccount().getCurrentPublicAddress(), fees: @transaction.fees, account: @account, utxo: @transaction.inputs
    @getDialog().push preparingDialog

  _updateTotalLabel: (fees, counterValueFee, amount = ledger.Amount.fromSatoshi(10000)) ->
    @view.totalLabel.text ledger.formatters.formatValue(amount.add(fees)) + ' ' + _.str.sprintf(t('wallet.send.index.transaction_fees_text'), ledger.formatters.formatValue(fees))
    @view.counterValueTotalLabel.html ledger.converters.satoshiToCurrencyFormatted(amount.add(fees)) + ' ' + _.str.sprintf(t('wallet.send.index.transaction_fees_text'), counterValueFee)
