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
        @_routeToNextDialog(transaction)

  _routeToNextDialog: (transaction) ->
    cardBlock = (transaction) =>
      @getDialog().push new WalletSendCardDialogViewController(transaction: transaction, options: {hideOtherValidationMethods: true})
    mobileBlock = (transaction, secureScreens) =>
      @getDialog().push new WalletSendMobileDialogViewController(transaction: transaction, secureScreens: secureScreens)
    methodBlock = (transaction) =>
      @getDialog().push new WalletSendMethodDialogViewController(transaction: transaction)

    # if mobile validation is supported
    if ledger.app.wallet.getIntFirmwareVersion() >= ledger.wallet.Firmware.V_LW_1_0_0
      # fetch grouped paired screens
      ledger.m2fa.PairedSecureScreen.getAllGroupedByUuidFromSyncedStore (groups, error) =>
        groups = _.values(_.omit(groups, undefined)) if groups?
        ## if paired and only one pairing id exists
        if error? or not groups? or groups.length != 1 or transaction.getValidationMode() != ledger.wallet.transaction.Transaction.ValidationModes.SECURE_SCREEN
          methodBlock(transaction)
        else
          mobileBlock(transaction, groups[0])
    else
      cardBlock(transaction)