class @WalletP2shSigningDialogViewController extends ledger.common.DialogViewController

  view:
    contentContainer: '#content_container'
    
  onAfterRender: ->
    super
    @view.spinner = ledger.spinners.createLargeSpinner(@view.contentContainer[0])
    @inputs = @params.inputs
    @scripts = @params.scripts
    @outputs_number = @params.outputs_number
    @outputs_script = @params.outputs_script
    @paths = @params.paths
    ledger.app.dongle.signP2SHTransaction(@inputs, @scripts, @outputs_number, @outputs_script, @paths)
    .then (signatures) =>
      Api.callback_success('sign_p2sh', {signatures: signatures})
      @dismiss =>
        dialog = new CommonDialogsMessageDialogViewController(kind: "success", title: t("wallet.p2sh.errors.signature_successfull"))
        dialog.show()
    .fail (error) =>
      Api.callback_cancel('sign_p2sh', t("wallet.p2sh.errors.signature_failed"))
      @dismiss =>
        dialog = new CommonDialogsMessageDialogViewController(kind: "error", title: t("wallet.p2sh.errors.signature_failed"), subtitle: error)
        dialog.show()
