class @WalletSendProcessingDialogViewController extends @DialogViewController

  view:
    contentContainer: '#content_container'

  onAfterRender: ->
    super
    @view.spinner = ledger.spinners.createLargeSpinner(@view.contentContainer[0])
    do @_startSignature

  _startSignature: ->
    # sign transaction
    @params.transaction.validate @params.keycode, (transaction, error) =>
      return if not @isShown()
      if error?
        @dismiss =>
          reason = switch error.code
            when ledger.errors.SignatureError then 'wrong_keycode'
            when ledger.errors.UnknownError then 'unknown'
          dialog = new WalletSendErrorDialogViewController reason: reason
          dialog.show()
      else
        @_startSending()

  _startSending: ->
    # push transaction
    ledger.api.TransactionsRestClient.instance.postTransaction @params.transaction, (transaction, error) =>
      return if not @isShown()
      @dismiss =>
        if error?
          dialog = new WalletSendErrorDialogViewController reason: 'network_no_response'
          dialog.show()
        else
          dialog = new CommonDialogsMessageDialogViewController(kind: "success", title: t("wallet.send.errors.sending_succeeded"), subtitle: t("wallet.send.errors.transaction_completed"))
          dialog.show()
