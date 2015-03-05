class @WalletPairingProgressDialogViewController extends DialogViewController

  view:
    spinnerContainer: "#spinner_container"
    contentContainer: "#content-container"

  onAfterRender: ->
    super
    # launch request
    @_request = @params.request
    @_request.onComplete (screen, error) =>
      @getDialog().push new WalletPairingErrorDialogViewController(reason: error) if error?
    @_onFinalizing = @_onFinalizing.bind(@)
    @_request.on 'finalizing', @_onFinalizing

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
