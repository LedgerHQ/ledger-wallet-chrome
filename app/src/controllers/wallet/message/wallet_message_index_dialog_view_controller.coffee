class @WalletMessageIndexDialogViewController extends ledger.common.DialogViewController

  view:
    derivationPath: '#derivation_path'
    message: '#message'
    confirmButton: '#confirm_button'

  onAfterRender: ->
    super
    chrome.app.window.current().show()
    @path = Api.cleanPath(@params.path)
    @message = @params.message
    @view.derivationPath.text("m/" + @path)
    @view.message.text(@message)

  cancel: ->
    Api.callback_cancel 'sign_message', t('wallet.message.errors.cancelled')
    @dismiss()

  confirm: ->
    dialog = new WalletMessageProcessingDialogViewController(path: @path, message: @message)
    @getDialog().push dialog

