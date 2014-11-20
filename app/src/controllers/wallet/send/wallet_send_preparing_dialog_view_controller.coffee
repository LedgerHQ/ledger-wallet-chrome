class @WalletSendPreparingDialogViewController extends @DialogViewController

  view:
    spinnerContainer: '#spinner_container'

  onAfterRender: ->
    super
    @view.spinner = ledger.spinners.createLargeSpinner(@view.spinnerContainer[0])
    account = ledger.wallet.HDWallet.instance.getAccount(0)

    # fetch amount
    ledger.wallet.transaction.createAndPrepareTransaction @params.amount, 1000, @params.address, ["44'/0'/0'/0/1"], account.getCurrentChangeAddressPath(), (transaction, error) =>
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