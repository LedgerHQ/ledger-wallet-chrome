class @WalletSendPreparingDialogViewController extends @DialogViewController

  view:
    spinnerContainer: '#spinner_container'

  onAfterRender: ->
    super
    @view.spinner = ledger.spinners.createLargeSpinner(@view.spinnerContainer[0])
    account = Account.find(index: 0).first()

    # fetch amount
    ledger.wallet.transaction.createAndPrepareTransaction @params.amount, 10000, @params.address, account, account, (transaction, error) =>
      return if not @isShown()
      if error?
        reason = switch error.code
          when ledger.errors.NetworkError then 'network_no_response'
          when ledger.errors.NotEnoughFunds then 'unsufficient_balance'
        @once 'dismiss', =>
          dialog = new WalletSendErrorDialogViewController reason: reason
          dialog.show()
        @dismiss()
      else
        invertModes = _.invert(ledger.wallet.transaction.Transaction.ValidationModes)
        l "[PreparingTxDialog]", invertModes[transaction.getValidationMode()], transaction
        switch transaction.getValidationMode()
          when ledger.wallet.transaction.Transaction.ValidationModes.KEYCARD
            @once 'dismiss', =>
              dialog = new WalletSendValidationDialogViewController transaction: transaction
              dialog.show()
            @dismiss()
          when ledger.wallet.transaction.Transaction.ValidationModes.SECURE_SCREEN
            l "%c[M2FA] Secure screen dialog in preparation", "#888888"
            @_requestValidation(transaction)

  _requestValidation: (tx) ->
    ledger.m2fa.validateTxOnAll(tx).fail( (error) =>
      # return if not @isShown()
      @once 'dismiss', =>
        dialog = new WalletSendErrorDialogViewController(reason: error)
        dialog.show()
      @dismiss()
    ).then( () =>
      # return if not @isShown()
      @once 'dismiss', =>
        dialog = new WalletSendProcessingDialogViewController transaction: tx
        dialog.show()
      @dismiss()
    ).done()
