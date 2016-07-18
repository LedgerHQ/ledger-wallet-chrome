class @WalletSendSignDialogViewController extends ledger.common.DialogViewController

  view:
    validatingContentContainer: '#validating'
    confirmContentContainer: '#confirm'
    processingContentContainer: '#processing'
    validatingProgressbarContainer: '#validating_progressbar_container'
    processingProgressbarContainer: '#processing_progressbar_container'
    validatingProgressLabel: "#validating_progress_label"
    processingProgressLabel: "#processing_progress_label"

  cancellable: no

  initialize: ->
    super
    @params.transaction.sign().progress (p) =>
      return unless @isShown()
      @_onSignatureProgress(p)
    .then (transaction) =>
      return unless @isShown()
      @_postTransaction(transaction)
      return
    .fail (error) =>
      reason = switch error.code
        when ledger.errors.SignatureError then 'unable_to_validate'
        when ledger.errors.UnknownError then 'unknown'
      @dismiss =>
        Api.callback_cancel 'send_payment', t("common.errors." + reason)
        dialog = new CommonDialogsMessageDialogViewController(kind: "error", title: t("wallet.send.errors.sending_failed"), subtitle: t("common.errors." + reason))
        dialog.show()

  _onSignatureProgress: (progress) ->
    l progress
    if progress.currentHashOutputBase58 is 1 and progress.currentUntrustedHash is 0
      @_invalidate('confirm')
    else if progress.currentHashOutputBase58 is 0
      # Validating
      currentStep = progress.currentTrustedInput + progress.currentPublicKey
      stepsCount = 2 * progress.publicKeyCount
      percent = Math.ceil(currentStep / stepsCount * 100)
      @_invalidateProgressBar(percent)
    else if progress.currentHashOutputBase58 is 1 and progress.currentUntrustedHash is 1
      # Enter processing
      @_invalidate('processing')
    else
      # Processing
      currentStep = progress.currentUntrustedHash + progress.currentSignTransaction
      stepsCount = 2 * progress.publicKeyCount
      percent = Math.ceil(currentStep / stepsCount * 100)
      @_invalidateProgressBar(percent)


  _invalidateProgressBar: (percent) ->
    @view["#{@_currentMode}ProgressBar"].setProgress(percent / 100)
    @view["#{@_currentMode}ProgressLabel"].text percent + '%'

  _currentMode: 'validating'
  _invalidate: (mode = undefined) ->
    @_currentMode = mode if mode?
    for key, container of @view when key.endsWith("ContentContainer")
      if key.startsWith(@_currentMode)
        container.show()
      else
        container.hide()

  _postTransaction: (transaction) ->
    ledger.api.TransactionsRestClient.instance.postTransaction transaction, (transaction, error) =>
      return if not @isShown()
      @dismiss =>
        dialog =
          if error?.isDueToNoInternetConnectivity()
            Api.callback_cancel 'send_payment', t("common.errors.network_no_response")
            new CommonDialogsMessageDialogViewController(kind: "error", title: t("wallet.send.errors.sending_failed"), subtitle: t("common.errors.network_no_response"))
          else if error?
            Api.callback_cancel 'send_payment', t("common.errors.push_transaction_failed")
            new CommonDialogsMessageDialogViewController(kind: "error", title: t("wallet.send.errors.sending_failed"), subtitle: t("common.errors.error_occurred"))
          else
            Api.callback_success 'send_payment', transaction: transaction.serialize()
            new CommonDialogsMessageDialogViewController(kind: "success", title: t("wallet.send.errors.sending_succeeded"), subtitle: t("wallet.send.errors.transaction_completed"))
        dialog.show()

  onAfterRender: ->
    super
    @_invalidate()
    @view.validatingProgressBar = new ledger.progressbars.ProgressBar(@view.validatingProgressbarContainer)
    @view.processingProgressBar = new ledger.progressbars.ProgressBar(@view.processingProgressbarContainer)
