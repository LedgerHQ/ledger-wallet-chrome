class @WalletApiAccountsDialogViewController extends ledger.common.DialogViewController

  cancellable: no

  cancel: ->
    Api.callback_cancel 'get_accounts', t('wallet.api.errors.cancelled')
    @dismiss()

  confirm: ->
    Api.exportAccounts()
    @dismiss()