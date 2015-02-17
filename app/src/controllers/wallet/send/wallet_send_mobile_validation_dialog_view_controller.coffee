class @WalletSendMobileValidationDialogViewController extends @DialogViewController

  view:
    spinnerContainer: '#spinner_container'

  onAfterRender: ->
    super
    @view.spinner = ledger.spinners.createLargeSpinner(@view.spinnerContainer[0])
    ledger.m2fa.validateTxOnAll(@params.transaction).fail( (error) =>
      # return if not @isShown()
      @once 'dismiss', =>
        dialog = new WalletSendErrorDialogViewController(reason: error)
        dialog.show()
      @dismiss()
    ).then( (keycode) =>
      # return if not @isShown()
      @once 'dismiss', =>
        dialog = new WalletSendProcessingDialogViewController transaction: @params.transaction, keycode: keycode
        dialog.show()
      @dismiss()
    ).done()

