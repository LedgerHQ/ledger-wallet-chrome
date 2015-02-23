class @WalletPairingProgressDialogViewController extends DialogViewController

  view:
    progress: "#progress"

  initialize: ->
    super

  onAfterRender: ->
    super
    @_request = @params.request
    @view.progress.text("Answer the challenge!")
    @_request.onComplete (screen, error) =>
      @getDialog().push new WalletPairingErrorDialogViewController(reason: error) if error?

    #request.on ''

  onShow: ->
    super

  onDismiss: ->
    super
    @_request?.cancel()
