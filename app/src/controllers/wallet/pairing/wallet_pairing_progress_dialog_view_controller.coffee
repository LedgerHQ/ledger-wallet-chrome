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
    @_onChallenge = @_onChallenge.bind(@)
    @_onFinalizing = @_onFinalizing.bind(@)
    @_request.on 'answerChallenge', @_onChallenge
    @_request.on 'finalizing', @_onFinalizing

  onShow: ->
    super

  onDetach: ->
    super
    @_request?.off 'answerChallenge', @_onChallenge
    @_request?.off 'finalizing', @_onFinalizing

  onDismiss: ->
    super
    @_request?.cancel()

  _onChallenge: ->
    @view.progress.text("Challenge received!")

  _onFinalizing: ->
    @getDialog().push new WalletPairingFinalizingDialogViewController(request: @_request)
