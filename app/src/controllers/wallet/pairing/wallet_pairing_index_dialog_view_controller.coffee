class @WalletPairingIndexDialogViewController extends DialogViewController

  initialize: ->
    super

  onAfterRender: ->
    super
    @_request = ledger.m2fa.requestPairing()
    @view.qrcode = new QRCode "qrcode_frame",
        text: @_request.pairingId
        width: 196
        height: 196
        colorDark : "#000000"
        colorLight : "#ffffff"
        correctLevel : QRCode.CorrectLevel.H
    @_onSendChallenge = @_onSendChallenge.bind(this)
    @_request.on 'sendChallenge', @_onSendChallenge
    @_request.onComplete (screen, error) =>
      if error is ledger.m2fa.PairingRequest.Errors.NeedPowerCycle
        @getDialog().push new WalletPairingErrorDialogViewController(reason: error)
      else
        @getDialog().push new WalletPairingErrorDialogViewController(reason: error)

  onShow: ->
    super

  onDetached: ->
    super
    @_request?.off 'sendChallenge', @_onSendChallenge

  onDismiss: ->
    super
    @_request?.cancel()

  _onSendChallenge: ->
    request = @_request
    @_request?.off 'sendChallenge', @_onSendChallenge
    @_request = null
    @getDialog().push new WalletPairingProgressDialogViewController(request: request)