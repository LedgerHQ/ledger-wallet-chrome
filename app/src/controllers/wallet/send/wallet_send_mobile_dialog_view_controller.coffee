class @WalletSendMobileDialogViewController extends @DialogViewController

  view:
    mobileName: "#mobile_name"

  onAfterRender: ->
    super
    ## request validation
    @_request = ledger.m2fa.requestValidation(@params.transaction, @params.secureScreens)
    @_request.onComplete (keycode, error) =>
      if error?
        @_request = null
        @dismiss =>
          dialog = new WalletSendErrorDialogViewController reason: error
          dialog.show()
      else
        dialog = new WalletSendProcessingDialogViewController transaction: @params.transaction, keycode: keycode
        @getDialog().push dialog
    ## update UI
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