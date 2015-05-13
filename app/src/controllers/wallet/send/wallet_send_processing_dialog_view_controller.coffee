class @WalletSendProcessingDialogViewController extends ledger.common.DialogViewController

  view:
    contentContainer: '#content_container'
    progressbarContainer: '#progressbar_container'
    progressLabel: "#progress_label"

  initialize: ->
    super
    @_startSignature()

  onAfterRender: ->
    super
    @view.progressBar = new ledger.progressbars.ProgressBar(@view.progressbarContainer)

  _startSignature: ->
    # sign transaction
    promise = if @params.keycode? then @params.transaction.validateWithKeycard(@params.keycode) else @params.transaction.validateWithPinCode(@params.pincode)
    promise.onComplete (transaction, error) =>
      return if not @isShown()
      if error?
        @dismiss =>
          reason = switch error.code
            when ledger.errors.SignatureError then 'wrong_keycode'
            when ledger.errors.UnknownError then 'unknown'
          Api.callback_cancel 'send_payment', t("common.errors." + reason)
          dialog = new CommonDialogsMessageDialogViewController(kind: "error", title: t("wallet.send.errors.sending_failed"), subtitle: t("common.errors." + reason))
          dialog.show()
      else
        @_startSending()
    promise.progress ({percent}) =>
      @view.progressBar.setProgress(percent / 100)
      @view.progressLabel.text percent + '%'

  _startSending: ->
    # push transaction
    ledger.api.TransactionsRestClient.instance.postTransaction @params.transaction, (transaction, error) =>
      return if not @isShown()
      @dismiss =>
        dialog =
        if error?.isDueToNoInternetConnectivity()
          Api.callback_cancel 'send_payment', t("common.errors.network_no_response")
          new CommonDialogsMessageDialogViewController(kind: "error", title: t("wallet.send.errors.sending_failed"), subtitle: t("common.errors.network_no_response"))
        else if error?
          Api.callback_cancel 'send_payment', t("common.errors.wrong_transaction_signature")
          new CommonDialogsMessageDialogViewController(kind: "error", title: t("wallet.send.errors.sending_failed"), subtitle: t("common.errors.wrong_transaction_signature"))
        else
          Api.callback_success 'send_payment', transaction: transaction.serialize()
          new CommonDialogsMessageDialogViewController(kind: "success", title: t("wallet.send.errors.sending_succeeded"), subtitle: t("wallet.send.errors.transaction_completed"))
        dialog.show()
