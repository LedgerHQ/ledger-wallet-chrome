class @WalletSendValidatingDialogViewController extends @DialogViewController

  view:
    contentContainer: '#content_container'

  onAfterRender: ->
    super
    @view.spinner = ledger.spinners.createLargeSpinner(@view.contentContainer[0])
    @params.transaction.prepare (transaction, error) =>
      return unless @isShown()
      if error?
        reason = switch error.code
          when ledger.errors.SignatureError then 'unable_to_validate'
          when ledger.errors.UnknownError then 'unknown'
        @dismiss =>
          dialog = new CommonDialogsMessageDialogViewController(kind: "error", title: t("wallet.send.errors.sending_failed"), subtitle: t("common.errors." + reason))
          dialog.show()
      else if @params.validationMode is 'card'
        @getDialog().push new WalletSendCardDialogViewController(transaction: transaction, options: @params.options)
      else
        @getDialog().push new WalletSendMobileDialogViewController(transaction: transaction, secureScreens: @params.secureScreens)