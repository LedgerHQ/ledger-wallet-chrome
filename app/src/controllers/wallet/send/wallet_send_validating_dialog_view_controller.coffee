class @WalletSendValidatingDialogViewController extends ledger.common.DialogViewController

  view:
    contentContainer: '#content_container'
    progressbarContainer: '#progressbar_container'
    progressLabel: "#progress_label"

  initialize: ->
    super
    promise = @params.transaction.prepare (transaction, error) =>
      return unless @isShown()
      if error?
        reason = switch error.code
          when ledger.errors.SignatureError then 'unable_to_validate'
          when ledger.errors.UnknownError then 'unknown'
        @dismiss =>
          Api.callback_cancel 'send_payment', t("common.errors." + reason)
          dialog = new CommonDialogsMessageDialogViewController(kind: "error", title: t("wallet.send.errors.sending_failed"), subtitle: t("common.errors." + reason))
          dialog.show()
      else if @params.validationMode is 'card' and no
        @getDialog().push new WalletSendCardDialogViewController(transaction: transaction, options: @params.options)
      else if no
        @getDialog().push new WalletSendMobileDialogViewController(transaction: transaction, secureScreens: @params.secureScreens)
      else
        @_startSending(transaction)
    promise.progress ({percent}) =>
      @view.progressBar.setProgress(percent / 100)
      @view.progressLabel.text percent + '%'

  _startSending: (transaction) ->
    # push transaction
    l "About to push ", transaction.getSignedTransaction()
    ledger.api.TransactionsRestClient.instance.postTransaction transaction, (transaction, error) =>
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

  cancel: ->
    Api.callback_cancel 'send_payment', t('wallet.send.errors.cancelled')
    @dismiss()

  onAfterRender: ->
    super
    @view.progressBar = new ledger.progressbars.ProgressBar(@view.progressbarContainer)
