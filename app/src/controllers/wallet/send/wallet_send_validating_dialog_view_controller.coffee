class @WalletSendValidatingDialogViewController extends @DialogViewController

  view:
    contentContainer: '#content_container'

  initialize: ->
    super
    @params.transaction.prepare (transaction, error) =>
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

  cancel: ->
    Api.callback_cancel 'send_payment', t('wallet.send.errors.cancelled')
    @dismiss()

  onAfterRender: ->
    super
    @view.spinner = ledger.spinners.createLargeSpinner(@view.contentContainer[0])