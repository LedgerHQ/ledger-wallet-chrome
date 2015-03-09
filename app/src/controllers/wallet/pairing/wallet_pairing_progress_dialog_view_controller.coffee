class @WalletPairingProgressDialogViewController extends DialogViewController

  view:
    contentContainer: "#content_container"

  onAfterRender: ->
    super
    # launch request
    @_request = @params.request
    @_request?.onComplete (screen, error) =>
      return if not error?
      @_request = null
      @once 'dismiss', =>
        # show error
        dialog = new CommonDialogsMessageDialogViewController(kind: "error", title: t("wallet.pairing.errors.pairing_failed"), subtitle: t("wallet.pairing.errors." + error))
        dialog.show()
      @dismiss()
    @_request?.on 'finalizing', @_onFinalizing
    # show spinner
    @view.spinner = ledger.spinners.createLargeSpinner(@view.contentContainer[0])

  onDetach: ->
    super
    @_request?.off 'finalizing', @_onFinalizing

  onDismiss: ->
    super
    @_request?.cancel()

  _onFinalizing: ->
    @getDialog().push new WalletPairingFinalizingDialogViewController(request: @_request)
