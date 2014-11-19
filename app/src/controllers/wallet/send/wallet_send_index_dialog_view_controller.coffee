class @WalletSendIndexDialogViewController extends DialogViewController

  view:
    amountInput: '#amount_input'

  onAfterRender: () ->
    super
    @view.amountInput.amountInput()

  onShow: ->
    super
    @view.amountInput.focus()

  send: ->
    @dismiss()
