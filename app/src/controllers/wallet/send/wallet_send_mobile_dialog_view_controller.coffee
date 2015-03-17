class @WalletSendMobileDialogViewController extends @DialogViewController

  onAfterRender: ->
    super
    ## request validation
    ledger.m2fa.PairedSecureScreen.getMostRecentFromSyncedStore (screen) =>
      @_request = ledger.m2fa.requestValidation(@params.transaction, screen)
      @_request.onComplete (keycode, error) =>
        if error?
          @_request = null
          @dismiss =>
            dialog = new WalletSendErrorDialogViewController reason: error
            dialog.show()
        else
          dialog = new WalletSendProcessingDialogViewController transaction: @params.transaction, keycode: keycode
          @getDialog().push dialog

  onDismiss: () ->
    super
    @_request?.cancel()