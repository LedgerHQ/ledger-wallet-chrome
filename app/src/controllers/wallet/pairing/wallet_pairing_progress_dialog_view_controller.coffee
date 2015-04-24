class @WalletPairingProgressDialogViewController extends DialogViewController

  view:
    contentContainer: "#content_container"

  onAfterRender: ->
    super
    # show spinner
    @view.spinner = ledger.spinners.createLargeSpinner(@view.contentContainer[0])

    # launch request
    @_request = @params.request
    @_request?.onComplete @_onComplete
    @_request?.on 'finalizing', @_onFinalizing

  onDetach: ->
    super
    @_request?.off 'finalizing', @_onFinalizing

  onDismiss: ->
    super
    @_request?.cancel()

  _onFinalizing: ->
    ledger.m2fa.PairedSecureScreen.getScreensByUuidFromSyncedStore @_request.getDeviceUuid(), (screens, error) =>
      if screens?.length is 0
        @getDialog().push new WalletPairingFinalizingDialogViewController(request: @_request)
      else
        @_request.setSecureScreenName(screens[0].name)

  _onComplete: (screen, error) ->
    @_request = null
    @dismiss () =>
      if screen?
        dialog = new CommonDialogsMessageDialogViewController(kind: "success", title: t("wallet.pairing.errors.pairing_succeeded"), subtitle: _.str.sprintf(t("wallet.pairing.errors.dongle_is_now_paired"), screen.name))
      else
        dialog = new CommonDialogsMessageDialogViewController(kind: "error", title: t("wallet.pairing.errors.pairing_failed"), subtitle: t("wallet.pairing.errors." + error))
      dialog.show()