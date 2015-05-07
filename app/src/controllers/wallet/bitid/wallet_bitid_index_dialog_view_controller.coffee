class @WalletBitidIndexDialogViewController extends ledger.common.DialogViewController

  view:
    confirmButton: '#confirm_button'
    errorContainer: '#error_container'
    bitidDomain: '#bitid_domain'
    bitidAddress: '#bitid_address'

  onAfterRender: ->
    super
    @view.confirmButton.addClass "disabled"
    @uri = @params.uri
    @doNotBroadcast = @params.silent
    @view.bitidDomain.text ledger.bitcoin.bitid.uriToDerivationUrl(@uri)
    ledger.bitcoin.bitid.getAddress(uri: @uri)
    .then (data) =>
      @address = data.bitcoinAddress.value
      @view.bitidAddress.text(@address)
      ledger.bitcoin.bitid.signMessage(@uri, uri: @uri)
    .then (sig) =>
      @signature = sig
      @view.confirmButton.removeClass "disabled"
      if typeof @signature != "string" || @signature.length == 0
        @view.errorContainer.text t('wallet.bitid.errors.signature_failed')
        @view.confirmButton.text t('common.close')
      else
        @view.confirmButton.text t('common.confirm')
    .catch (error) =>
      console.error(error)
      @view.errorContainer.text t("wallet.bitid.errors.signature_failed")
      @view.confirmButton.text t('common.close')
    .done()

  cancel: ->
    Api.callback_cancel 'bitid', t('wallet.bitid.errors.cancelled')
    @dismiss()

  confirm: ->
    Api.callback_success 'bitid',
      address: @address,
      signature: @signature,
      uri: @uri
    if typeof @signature != "string" || @signature.length == 0 || @doNotBroadcast == "true"
      @dismiss()
    else
      dialog = new WalletBitidAuthenticatingDialogViewController uri: @uri, address: @address, signature: @signature
      @getDialog().push dialog