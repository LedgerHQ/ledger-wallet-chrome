class @WalletSendProcessingDialogViewController extends @DialogViewController

  view:
    title: '#title'
    spinnerContainer: '#spinner_container'

  onAfterRender: ->
    super
    @view.spinner = ledger.spinners.createLargeSpinner(@view.spinnerContainer[0])
    do @_startSignature

  _startSignature: ->
    @view.title.text t 'wallet.send.processing.validating'
    # sign transaction
    @params.transaction.validate @params.keycode, (transaction, error) =>
      return if not @isShown()
      if error?
        @once 'dismiss', =>
          reason = switch error.code
            when ledger.errors.SignatureError then 'wrong_keycode'
            when ledger.errors.UnknownError then 'unknown'
          dialog = new WalletSendErrorDialogViewController reason: reason
          dialog.show()
        @dismiss()
      else
        @_startSending()

  _startSending: ->
    @view.title.text t 'wallet.send.processing.sending'
    # push transaction
    ledger.api.TransactionsRestClient.instance.postTransaction @params.transaction, (transaction, error) =>
      return if not @isShown()
      @once 'dismiss', =>
        if error?
          dialog = new WalletSendErrorDialogViewController reason: 'network_no_response'
          dialog.show()
        else
          dialog = new WalletSendSuccessDialogViewController
          dialog.show()
      @dismiss()