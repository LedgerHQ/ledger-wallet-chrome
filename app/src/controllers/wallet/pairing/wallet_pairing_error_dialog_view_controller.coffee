class @WalletPairingProgressDialogViewController extends DialogViewController

  view:
    progress: "#progress"

  initialize: ->
    super

  onAfterRender: ->
    super
    @_request = @params.request
    @view.progress.text("Answer the challenge!")

    #request.on ''

  onShow: ->
    super

  onDismiss: ->
    super
    @_request?.cancel()
