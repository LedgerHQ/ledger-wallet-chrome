
class @WalletAccountsAccountSendDialogViewController extends DialogViewController

  onAfterRender: () ->
    super
    @select('#amount_input').numberInput()

  onShow: ->
    super
    @select('#amount_input').focus()