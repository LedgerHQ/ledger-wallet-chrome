class @WalletBitidIndexDialogViewController extends DialogViewController

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
    @derivationPath = ledger.bitcoin.bitid.uriToDerivationPath(@uri)
    @view.bitidDomain.text ledger.bitcoin.bitid.uriToDerivationUrl(@uri)
    ledger.app.wallet._lwCard.getBitIDAddress @derivationPath
    .then (data) =>
      @address = data.bitcoinAddress.value
      @view.bitidAddress.text(@address)
      ledger.app.wallet.signMessageWithBitId @derivationPath, @uri, (result) =>
        @signature = result
        @view.confirmButton.removeClass "disabled"
        if typeof @signature != "string" || @signature.length == 0
          @view.errorContainer.text t('wallet.bitid.errors.signature_failed')
          @view.confirmButton.text t('common.close')
        else
          @view.confirmButton.text t('common.confirm')

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