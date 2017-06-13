class @WalletSendCpfpDialogViewController extends ledger.common.DialogViewController

  view:
    feesPerByte: '#fees_per_byte'
    check: '#check'
    message: '#message'
    feesPerByte: '#fees_per_byte'
    sendButton: '#send_button'
    totalLabel: '#total_label'
    counterValueTotalLabel: '#countervalue_total_label'



  initialize: () ->
    super
    l @params
    @operation = @params.operation
    @account = @params.account
    @transaction = @params.transaction
    @amount = ledger.formatters.formatValue(ledger.Amount.fromSatoshi(10000))
    @address = @params.account.getWalletAccount().getCurrentPublicAddress()
    @fees = @transaction.fees
    @countervalue = ledger.converters.satoshiToCurrencyFormatted(@fees)
    @feesPerByte = @fees.divide(@transaction.size)

  onShow: () ->
    super
    @view.feesPerByte.focus()

  onAfterRender: () ->
    super
    @view.message.text(t('wallet.cpfp.message'))
    @view.check.text(t('wallet.cpfp.check'))
    @_updateTotalLabel(@fees, @countervalue)
    @view.feesPerByte.keypress (e) =>
      if (e.which < 48 || 57 < e.which || @view.feesPerByte.val() > 999)
        e.preventDefault()
    @view.feesPerByte.on 'keyup', _.debounce(
      () =>
        ledger.bitcoin.cpfp.createTransaction(@account, @operation.get("hash"), @view.feesPerByte.val() * @transaction.size)
          .then((transaction) =>
            @view.sendButton.removeClass('disabled')
            @view.feesPerByte.removeClass('red')
            @transaction = transaction
            @feesPerByte = @view.feesPerByte.val()
            @fees = @feesPerByte * @transaction.size
            @countervalue = ledger.converters.satoshiToCurrencyFormatted(@fees)
            @_updateTotalLabel(@fees, @countervalue)
          ).catch((err) =>
            e err
            @view.sendButton.addClass('disabled')
            @view.feesPerByte.addClass('red')
          )
      ,500)

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
