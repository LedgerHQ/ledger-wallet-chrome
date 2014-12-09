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
      @once 'dismiss', =>
        if error?
          reason = switch error.code
            when ledger.errors.NetworkError then 'network_no_response'
            when ledger.errors.NotEnoughFunds then 'unsufficient_balance'
          dialog = new WalletSendErrorDialogViewController reason: reason
          dialog.show()
        else
          dialog = new WalletSendValidationDialogViewController transaction: transaction
          dialog.show()
      @dismiss()