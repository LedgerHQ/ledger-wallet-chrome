class @WalletBitidAuthenticatingDialogViewController extends ledger.common.DialogViewController

  view:
    contentContainer: '#content_container'

  onAfterRender: ->
    super
    @view.spinner = ledger.spinners.createLargeSpinner(@view.contentContainer[0])
    do @_startAuthenticating

  _startAuthenticating: ->
    ledger.bitcoin.bitid.callback(
      @params.uri,
      @params.address,
      @params.signature
    ).then(
      (result) =>
        if result.error?
          @_error(result.error)
        else
          @_success()
      , (jqXHR, textStatus, errorThrown) =>
        @_error(textStatus || t("errors.network_error"))
    )

  _success: ->
    console.log "success"
    @dismiss ->
      dialog = new CommonDialogsMessageDialogViewController(kind: "success", title: t("wallet.bitid.auth.succeeded"), subtitle: t("wallet.bitid.auth.completed"))
      dialog.show()

  _error: (reason) ->
    @dismiss ->
      dialog = new CommonDialogsMessageDialogViewController(kind: "error", title: t("wallet.bitid.auth.failed"), subtitle: reason)
      dialog.show()
