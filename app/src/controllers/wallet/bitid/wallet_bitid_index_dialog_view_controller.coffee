class @WalletBitidIndexDialogViewController extends DialogViewController

  view:
    confirmButton: '#confirm_button'
    errorContainer: '#error_container'
    bitidUrl: '#bitid_url'

  onAfterRender: () ->
    super
    #@view.amountInput.amountInput()
    do @_listenEvents

  onShow: ->
    super
    #@view.amountInput.focus()

  onDetach: ->
    super
    #@_stopScanner()

  onDismiss: ->
    super
    #@_stopScanner()

  confirm: ->
    nextError = @_nextFormError()
    if nextError?
      @view.errorContainer.show()
      @view.errorContainer.text nextError
    else
      @view.errorContainer.hide()
      dialog = new WalletSendPreparingDialogViewController amount: @_transactionAmount(), address: @_receiverBitcoinAddress()
      @getDialog().push dialog

  _listenEvents: ->

  _nextFormError: ->
    # check amount
    if @_transactionAmount().length == 0 or not ledger.wallet.Value.from(@_transactionAmount()).gt(0)
      return t 'common.errors.invalid_amount'
    else if not Bitcoin.Address.validate @_receiverBitcoinAddress()
      return t 'common.errors.invalid_receiver_address'
    undefined
