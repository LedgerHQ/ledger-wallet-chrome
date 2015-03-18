class @WalletSendPreparingDialogViewController extends @DialogViewController

  view:
    contentContainer: '#content_container'

  onAfterRender: ->
    super
    @view.spinner = ledger.spinners.createLargeSpinner(@view.contentContainer[0])
    account = Account.find(index: 0).first()

    # fetch amount
    ledger.wallet.transaction.createAndPrepareTransaction @params.amount, 10000, @params.address, account, account, (transaction, error) =>
      return if not @isShown()
      if error?
        reason = switch error.code
          when ledger.errors.NetworkError then 'network_no_response'
          when ledger.errors.NotEnoughFunds then 'unsufficient_balance'
        @dismiss =>
          dialog = new WalletSendErrorDialogViewController reason: reason
          dialog.show()
      else
        dialog = new WalletSendMethodDialogViewController(transaction: transaction)
        @getDialog().push dialog

  onDismiss: ->
    super

  onDetach: ->
    super
