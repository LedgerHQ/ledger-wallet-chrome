class @WalletSendMethodDialogViewController extends @DialogViewController

  view:
    mobileTableContainer: "#mobile_table_container"

  initialize: ->
    super
    @mobilesGroups = []

  cancel: ->
    Api.callback_cancel 'send_payment', t('wallet.send.errors.cancelled')
    @dismiss()
    
  onAfterRender: ->
    super
    @_refreshMobilesList()

  pairMobilePhone: ->
    dialog = new WalletPairingIndexDialogViewController()
    dialog.show()
    dialog.getDialog().once 'dismiss', =>
      @_refreshMobilesList()

  selectMobileGroup: (params) ->
    secureScreens = @mobilesGroups[params.index]
    dialog = new WalletSendValidatingDialogViewController(secureScreens: secureScreens, transaction: @params.transaction, validationMode: 'mobile')
    @getDialog().push dialog

  selectSecurityCard: ->
    dialog = new WalletSendValidatingDialogViewController(transaction: @params.transaction, validationMode: 'card')
    @getDialog().push dialog

  _refreshMobilesList: ->
    ledger.m2fa.PairedSecureScreen.getAllGroupedByUuidFromSyncedStore (mobilesGroups, error) =>
      return if error? or not mobilesGroups?
      mobilesGroups = _.sortBy _.values(_.omit(mobilesGroups, undefined)), (item) -> item[0]?.name
      # render partial
      render "wallet/send/_method_mobiles_list", mobilesGroups: mobilesGroups, (html) =>
        return if not html?
        # retain mobiles
        @mobilesGroups = mobilesGroups
        # clear node
        @view.mobileTableContainer.empty()
        @view.mobileTableContainer.append html