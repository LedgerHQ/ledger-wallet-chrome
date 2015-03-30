class @WalletBitidIndexDialogViewController extends DialogViewController

  view:
    confirmButton: '#confirm_button'
    errorContainer: '#error_container'
    bitidDomain: '#bitid_domain'
    bitidAddress: '#bitid_address'

  onAfterRender: ->
    super
    @view.bitidDomain.text(ledger.bitcoin.bitid.uriToDerivationUrl(@params['?params'].uri))

  confirm: ->
    nextError = @_nextFormError()
    if nextError?
      @view.errorContainer.show()
      @view.errorContainer.text nextError
    else
      @view.errorContainer.hide()
      dialog = new WalletSendPreparingDialogViewController amount: @_transactionAmount(), address: @_receiverBitcoinAddress()
      @getDialog().push dialog