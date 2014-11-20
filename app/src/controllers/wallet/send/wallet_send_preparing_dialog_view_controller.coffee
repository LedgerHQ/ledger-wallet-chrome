class @WalletSendPreparingDialogViewController extends @DialogViewController

  view:
    spinnerContainer: '#spinner_container'

  onAfterRender: ->
    super
    @view.spinner = ledger.spinners.createLargeSpinner(@view.spinnerContainer[0])

    # fetch amount
    _.delay =>
      return if not @isShown()
      @once 'dismiss', =>
        dialog = new WalletSendValidationDialogViewController()
        dialog.show()
      @dismiss()
    , 3000