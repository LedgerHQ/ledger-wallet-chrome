class @WalletApiOperationsDialogViewController extends DialogViewController

  cancellable: no

  view:
    accountName: '#account_name'

  onAfterRender: ->
    super
    @account_id = parseInt(@params.account_id) || 1
    @account = Account.find({"id": @account_id}).first()
    if @account
      @view.accountName.text @account.get('name')
    else
      Api.callback_cancel 'get_operations', t('wallet.api.errors.account_not_found')
      @dismiss()

  cancel: ->
    Api.callback_cancel 'get_operations', t('wallet.api.errors.cancelled')
    @dismiss()

  confirm: ->
    Api.exportOperations(@account_id)
    @dismiss()