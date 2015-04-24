class @WalletBitidFormDialogViewController extends DialogViewController

  view:
    bitidUri: '#bitid_uri'
    errorContainer: '#error_container'

  onShow: ->
    super
    @view.bitidUri.focus()

  next: ->
    nextError = @_nextFormError()
    if nextError?
      @view.errorContainer.show()
      @view.errorContainer.text nextError
    else
      @view.errorContainer.hide()     
      dialog = new WalletBitidIndexDialogViewController uri: @_uri(), silent: true
      @getDialog().push dialog

  _uri: ->
    _.str.trim(@view.bitidUri.val())

  _nextFormError: ->
    if !ledger.bitcoin.bitid.isValidUri(@_uri())
      return t 'wallet.bitid.form.invalid_uri'
    undefined        