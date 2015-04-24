class @WalletSendMobileDialogViewController extends @DialogViewController

  view:
    mobileName: "#mobile_name"

  cancel: ->
    Api.callback_cancel 'send_payment', t('wallet.send.errors.cancelled')
    @dismiss()

  initialize: ->
    super
    @_request = ledger.m2fa.requestValidation(@params.transaction, @params.secureScreens)

  onAfterRender: ->
    super
    # request validation
    @_request.onComplete @_onComplete

    # update UI
    @view.mobileName.text _.str.sprintf(t('wallet.send.mobile.sending_transaction'), @params.secureScreens[0].name)

  onDetach: ->
    super
    @_request?.cancel()

  onDismiss: () ->
    super
    @_request?.cancel()

  otherValidationMethods: ->
    dialog = new WalletSendMethodDialogViewController(transaction: @params.transaction)
    @getDialog().push dialog

  _onComplete: (pincode, error) =>
    if error?
      @_request = null
      @dismiss =>
        Api.callback_cancel 'send_payment', t("common.errors." + error)
        dialog = new CommonDialogsMessageDialogViewController(kind: "error", title: t("wallet.send.errors.sending_failed"), subtitle: t("common.errors." + error))
        dialog.show()
    else
      dialog = new WalletSendProcessingDialogViewController transaction: @params.transaction, pincode: pincode
      @getDialog().push dialog