class @WalletP2shIndexDialogViewController extends DialogViewController

  view:
    confirmButton: '#confirm_button'

  onAfterRender: ->
    super
    chrome.app.window.current().show()
    @inputs = JSON.parse @params.inputs
    @scripts = JSON.parse @params.scripts
    @outputs_number = @params.outputs_number
    @outputs_script = @params.outputs_script
    @paths = JSON.parse @params.paths

  cancel: ->
    Api.callback_cancel 'p2sh', t('wallet.p2sh.errors.cancelled')
    @dismiss()

  confirm: ->
    dialog = new WalletP2shSigningDialogViewController inputs: @inputs, scripts: @scripts, outputs_number: @outputs_number, outputs_script: @outputs_script, paths: @paths
    @getDialog().push dialog