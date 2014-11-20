class @WalletSendIndexDialogViewController extends DialogViewController

  view:
    amountInput: '#amount_input'
    sendButton: '#send_button'
    totalInput: '#total_input'
    errorContainer: '#error_container'
    receiverInput: '#receiver_input'

  onAfterRender: () ->
    super
    @view.amountInput.amountInput()
    @view.errorContainer.hide()
    do @_updateTotalInput
    do @_listenEvents

  onShow: ->
    super
    @view.amountInput.focus()

  send: ->
    nextError = @_nextFormError()
    if nextError?
      @view.errorContainer.show()
      @view.errorContainer.text nextError
    else
      @view.errorContainer.hide()
      @once 'dismiss', =>
        dialog = new WalletSendPreparingDialogViewController()
        dialog.show()
      @dismiss()

  _listenEvents: ->
    @view.amountInput.on 'keydown', =>
      _.defer =>
        @_updateTotalInput yes

  _receiverBitcoinAddress: ->
    _.str.trim(@view.receiverInput.val())

  _transactionAmount: ->
    _.str.trim(@view.amountInput.val())

  _nextFormError: ->
    # check amount
    if @_transactionAmount().length == 0 or not ledger.wallet.Value.from(@_transactionAmount()).gt(0)
      return t 'common.errors.invalid_amount'
    else if not Bitcoin.Address.validate @_receiverBitcoinAddress()
      return t 'common.errors.invalid_receiver_address'
    undefined

  _updateTotalInput: ->
    val = parseInt(ledger.wallet.Value.from(@_transactionAmount()).add(1000).toString()) #+ 0.00001 btc
    @view.totalInput.text ledger.formatters.bitcoin.fromValue(val) + ' BTC ' + t 'wallet.send.index.transaction_fees_text'