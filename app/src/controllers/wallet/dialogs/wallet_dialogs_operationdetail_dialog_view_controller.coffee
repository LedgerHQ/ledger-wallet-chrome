class @WalletDialogsOperationdetailDialogViewController extends ledger.common.DialogViewController

  view:
    cpfpButton: "#cpfp_button"

  show: ->
    @operation = Operation.findById(parseInt(@params['operationId']))
    super

  onAfterRender: ->
    super
    @view.cpfpButton.hide() if @operation.get("confirmations") > 0 or !ledger.bitcoin.cpfp.isEligibleToCpfp(@operation.get("hash"))

  openBlockchain: ->
    exploreURL = ledger.preferences.instance.getBlockchainExplorerAddress()
    window.open _.str.sprintf(exploreURL, @operation.get('hash'))

  cpfp: ->
    @view.cpfpButton.addClass('disabled')
    account = @operation.get("account")
    @_createTransaction = ledger.bitcoin.cpfp.createTransaction(account, @operation.get("hash")).then (transaction) =>
      @view.cpfpButton.removeClass('disabled')
      return if not @isShown()
      dialog = new CommonDialogsConfirmationDialogViewController()
      #dialog.showsCancelButton = yes
      dialog.dismissAfterClick = no
      #dialog.negativeText = _.str.sprintf(t('wallet.send.index.no_use'), "")
      dialog.positiveLocalizableKey = 'common.yes'
      dialog.titleLocalizableKey = 'wallet.cpfp.title'
      amount = ledger.formatters.formatValue(ledger.Amount.fromSatoshi(10000))
      address = account.getWalletAccount().getCurrentPublicAddress()
      fees = ledger.formatters.formatValue(transaction.fees)
      countervalue = ledger.converters.satoshiToCurrencyFormatted(transaction.fees)
      dialog.message = _.str.sprintf(t('wallet.cpfp.message'), amount, address, fees, countervalue)
      dialog.once 'click:positive', =>
        preparingDialog = new WalletSendPreparingDialogViewController amount: 10000, address: account.getWalletAccount().getCurrentPublicAddress(), fees: transaction.fees, account: account, utxo: transaction.inputs
        dialog.getDialog().push preparingDialog
      dialog.once 'click:negative', ->
        dialog.dismiss()
      dialog.show()
    .fail (error) =>
      return if not @isShown()
      e error
      if error?
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