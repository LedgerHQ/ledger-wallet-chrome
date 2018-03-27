class @WalletDialogsOperationdetailDialogViewController extends ledger.common.DialogViewController

  view:
    cpfpButton: "#cpfp_button"

  show: ->
    @operation = Operation.findById(parseInt(@params['operationId']))
    super

  onAfterRender: ->
    super
    @view.cpfpButton.hide() if @operation.get("confirmations") > 0 or !ledger.bitcoin.cpfp.isEligibleToCpfp(@operation.get("hash")) or !["0", "1", "145"].includes(ledger.config.network.bip44_coin_type)

  openBlockchain: ->
    exploreURL = ledger.preferences.instance.getBlockchainExplorerAddress()
    window.open _.str.sprintf(exploreURL, @operation.get('hash'))

  cpfp: ->
    @view.cpfpButton.addClass('disabled')
    account = @operation.get("account")
    @_createTransaction = ledger.bitcoin.cpfp.createTransaction(account, @operation.get("hash")).then (transaction) =>
      @view.cpfpButton.removeClass('disabled')
      return if not @isShown()
      dialog = new WalletSendCpfpDialogViewController({transaction, account, operation: @operation})
      dialog.show()
    .fail (error) =>
      return if not @isShown()
      e error
      if error?
        if error.code == ledger.errors.FeesTooLowCpfp
          @view.cpfpButton.removeClass('disabled')
          return if not @isShown()
          dialog = new WalletSendCpfpDialogViewController({transaction: error.payload, account, operation: @operation})
          dialog.show()
        else
          reason = switch error.code
            when ledger.errors.NetworkError then 'network_no_response'
            when ledger.errors.NotEnoughFunds then 'unsufficient_balance'
            when ledger.errors.NotEnoughFundsConfirmed then 'unsufficient_balance'
            when ledger.errors.TransactionAlreadyConfirmed then 'transaction_already_confirmed'
            when ledger.errors.DustTransaction then 'dust_transaction'
            when ledger.errors.TransactionNotEligible then 'transaction_not_eligible'
            when ledger.errors.ChangeDerivationError then 'change_derivation_error'
            else 'error_occurred'

          errorMessage = switch reason
            when 'dust_transaction' then _.str.sprintf(t("common.errors." + reason), ledger.formatters.formatValue(ledger.wallet.Transaction.MINIMUM_OUTPUT_VALUE))
            else t("common.errors." + reason)
          dialog = new CommonDialogsMessageDialogViewController(kind: "error", title: t("wallet.send.errors.cpfp_failed"), subtitle: errorMessage)
          dialog.show()
