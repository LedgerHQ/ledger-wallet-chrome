class @WalletSendMobileDialogViewController extends @DialogViewController

  view:
    contentContainer: '#content_container'

  onAfterRender: ->
    super
    ## setup ui
    @view.spinner = ledger.spinners.createLargeSpinner(@view.contentContainer[0])
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
          @dismiss =>
            dialog = new WalletSendProcessingDialogViewController transaction: @params.transaction, keycode: keycode
            dialog.show()

  onDismiss: () ->
    super
    @_request?.cancel()