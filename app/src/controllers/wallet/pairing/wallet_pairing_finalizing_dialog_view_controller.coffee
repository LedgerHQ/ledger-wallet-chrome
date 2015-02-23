class @WalletPairingFinalizingDialogViewController extends DialogViewController

  view:
    screenNameInput: '#screenNameInput'

  onAfterRender: ->
    super
    @_request = @params.request
    @_request.onComplete (screen, error) =>
      @_request = null
      if screen?
        @getDialog().push new WalletPairingSuccessDialogViewController(screen: screen)
      else
        @getDialog().push new WalletPairingErrorDialogViewController(reason: error)

  submitScreenName: ->
    @_request.setSecureScreenName(@view.screenNameInput.val())

  onDismiss: ->
    super
    @_request?.cancel()