class @WalletSendPreparingDialogViewController extends @DialogViewController

  view:
    contentContainer: '#content_container'

  initialize: ->
    super
    # fetch amount
    account = Account.find(index: 0).first()
    account.createTransaction amount: @params.amount, fees: ledger.preferences.instance.getMiningFee(), address: @params.address, (transaction, error) =>
      return if not @isShown()
      if error?
        reason = switch error.code
          when ledger.errors.NetworkError then 'network_no_response'
          when ledger.errors.NotEnoughFunds then 'unsufficient_balance'
          when ledger.errors.DustTransaction then 'dust_transaction'
        @dismiss =>
          errorMessage = switch reason
            when 'dust_transaction' then _.str.sprintf(t("common.errors." + reason), ledger.formatters.formatValue(ledger.wallet.transaction.MINIMUM_OUTPUT_VALUE))
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
    cardBlock = (transaction) =>
      @getDialog().push new WalletSendValidatingDialogViewController(transaction: transaction, options: {hideOtherValidationMethods: true}, validationMode: 'card')
    mobileBlock = (transaction, secureScreens) =>
      @getDialog().push new WalletSendValidatingDialogViewController(transaction: transaction, secureScreens: secureScreens, validationMode: 'mobile')
    methodBlock = (transaction) =>
      @getDialog().push new WalletSendMethodDialogViewController(transaction: transaction)

    # if mobile validation is supported
    if ledger.app.wallet.getIntFirmwareVersion() >= ledger.wallet.Firmware.V_LW_1_0_0
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