class @WalletBitidIndexDialogViewController extends DialogViewController

  view:
    confirmButton: '#confirm_button'
    errorContainer: '#error_container'
    bitidDomain: '#bitid_domain'
    bitidAddress: '#bitid_address'

  onAfterRender: ->
    super
    @view.confirmButton.addClass "disabled"
    @uri = @params['?params'].uri
    @derivationPath = ledger.bitcoin.bitid.uriToDerivationPath(@uri)
    @view.bitidDomain.text ledger.bitcoin.bitid.uriToDerivationUrl(@uri)
    ledger.app.wallet._lwCard.getBitIDAddress @derivationPath
    .then (data) =>
      @address = data.bitcoinAddress.value
      @view.bitidAddress.text(@address)
      ledger.app.wallet.signMessageWithBitId @derivationPath, @uri, (result) =>
        @signature = result
        @view.confirmButton.text t('common.confirm')
        @view.confirmButton.removeClass "disabled"

  confirm: ->
    chrome.runtime.sendMessage {
      command: 'bitid',
      address: @address,
      signature: @signature,
      uri: @uri
    }
    dialog = new WalletBitidAuthenticatingDialogViewController uri: @uri, address: @address, signature: @signature
    @getDialog().push dialog