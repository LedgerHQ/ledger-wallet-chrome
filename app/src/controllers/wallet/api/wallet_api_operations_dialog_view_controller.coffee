class @WalletApiOperationsDialogViewController extends ledger.common.DialogViewController

  cancellable: no

  view:
    accountName: '#account_name'
    confirmButton: '#confirmButton'

  onAfterRender: ->
    super
    @account_id = parseInt(@params.account_id) || 1
    @account = Account.find({"id": @account_id}).first()
    if @account
      @view.accountName.text @account.get('name')
    else
      @view.accountName.text t('wallet.api.errors.account_not_found')
      @view.confirmButton.addClass "disabled"
      Api.callback_cancel 'get_operations', t('wallet.api.errors.account_not_found')

  cancel: ->
    Api.callback_cancel 'get_operations', t('wallet.api.errors.cancelled')
    @dismiss()

  confirm: ->
    Api.exportOperations(@account_id)
    @dismiss()