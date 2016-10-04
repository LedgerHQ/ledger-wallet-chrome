class @WalletSendPreparingDialogViewController extends ledger.common.DialogViewController

  view:
    contentContainer: '#content_container'

  initialize: ->
    super
    # fetch amount
    account = @_getAccount()
    account.createTransaction amount: @params.amount, fees: @params.fees, address: @params.address, utxo: @params.utxo, data: @params.data, (transaction, error) =>
      return if not @isShown()
      if error?
        reason = switch error.code
          when ledger.errors.NetworkError then 'network_no_response'
          when ledger.errors.NotEnoughFunds then 'unsufficient_balance'
          when ledger.errors.NotEnoughFundsConfirmed then 'unsufficient_balance'
          when ledger.errors.DustTransaction then 'dust_transaction'
          when ledger.errors.ChangeDerivationError then 'change_derivation_error'
          else 'error_occurred'
        @dismiss =>
          errorMessage = switch reason
            when 'dust_transaction' then _.str.sprintf(t("common.errors." + reason), ledger.formatters.formatValue(ledger.wallet.Transaction.MINIMUM_OUTPUT_VALUE))
            else t("common.errors." + reason)
          Api.callback_cancel 'send_payment', errorMessage
          dialog = new CommonDialogsMessageDialogViewController(kind: "error", title: t("wallet.send.errors.sending_failed"), subtitle: errorMessage)
          dialog.show()
      else
        @_routeToNextDialog(transaction)

  cancel: ->
    Api.callback_cancel 'send_payment', t('wallet.send.errors.cancelled')
    @dismiss()

  onAfterRender: ->
    super
    @view.spinner = ledger.spinners.createLargeSpinner(@view.contentContainer[0])

  _routeToNextDialog: (transaction) ->
    if ledger.app.dongle.getFirmwareInformation().hasScreenAndButton()
      @getDialog().push new WalletSendSignDialogViewController(transaction: transaction)
      return

    cardBlock = (transaction) =>
      @getDialog().push new WalletSendValidatingDialogViewController(transaction: transaction, options: {hideOtherValidationMethods: true}, validationMode: 'card')
    mobileBlock = (transaction, secureScreens) =>
      @getDialog().push new WalletSendValidatingDialogViewController(transaction: transaction, secureScreens: secureScreens, validationMode: 'mobile')
    methodBlock = (transaction) =>
      @getDialog().push new WalletSendMethodDialogViewController(transaction: transaction)

    # if mobile validation is supported
    if ledger.app.dongle.getFirmwareInformation().hasSecureScreen2FASupport()
      # fetch grouped paired screens
      ledger.m2fa.PairedSecureScreen.getAllGroupedByUuidFromSyncedStore (groups, error) =>
        groups = _.values(_.omit(groups, undefined)) if groups?
        ## if paired and only one pairing id exists
        if error? or not groups? or groups.length != 1
          methodBlock(transaction)
        else
          mobileBlock(transaction, groups[0])
    else
      cardBlock(transaction)

  _getAccount: -> @_account ||= @params.account
