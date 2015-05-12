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
      else if @params.validationMode is 'card'
        @getDialog().push new WalletSendCardDialogViewController(transaction: transaction, options: @params.options)
      else
        @getDialog().push new WalletSendMobileDialogViewController(transaction: transaction, secureScreens: @params.secureScreens)
    promise.progress ({percent}) =>
      @view.progressBar.setProgress(percent / 100)
      @view.progressLabel.text percent + '%'

  cancel: ->
    Api.callback_cancel 'send_payment', t('wallet.send.errors.cancelled')
    @dismiss()

  onAfterRender: ->
    super
    @view.progressBar = new ledger.progressbars.ProgressBar(@view.progressbarContainer)
