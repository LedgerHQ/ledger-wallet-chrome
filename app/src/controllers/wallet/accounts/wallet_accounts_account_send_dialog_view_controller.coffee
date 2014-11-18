class @WalletAccountsAccountSendDialogViewController extends DialogViewController

  onAfterRender: () ->
    super
    @select('#amount_input').amountInput()

  onShow: ->
    super
    @select('#amount_input').focus()