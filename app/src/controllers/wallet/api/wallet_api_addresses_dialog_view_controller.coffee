class @WalletApiAddressesDialogViewController extends ledger.common.DialogViewController

  cancellable: no

  view:
    accountName: '#account_name'
    count: '#count'
    confirmButton: '#confirmButton'

  onAfterRender: ->
    super
    @account_id = parseInt(@params.account_id) || 1
    @account = Account.find({"id": @account_id}).first()
    @count = parseInt(@params.count) || 1
    @view.count.text @count
    if @account
      @view.accountName.text @account.get('name')
    else
      @view.accountName.text t('wallet.api.errors.account_not_found')
      @view.confirmButton.addClass "disabled"      
      Api.callback_cancel 'get_new_addresses', t('wallet.api.errors.account_not_found')

  cancel: ->
    Api.callback_cancel 'get_net_addresses', t('wallet.api.errors.cancelled')
    @dismiss()

  confirm: ->
    Api.exportNewAddresses(@account_id, @count)
    @dismiss()