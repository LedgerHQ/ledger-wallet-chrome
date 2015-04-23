class @WalletApiAccountsDialogViewController extends DialogViewController

  cancellable: no

  cancel: ->
    Api.callback_cancel 'get_accounts', t('wallet.api.errors.cancelled')
    @dismiss()

  confirm: ->
    Api.exportAccounts()
    @dismiss()