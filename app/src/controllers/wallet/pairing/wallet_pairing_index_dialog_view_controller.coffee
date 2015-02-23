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
    @_onSendChallenge =  =>
      request = @_request
      @_request = null
      @getDialog().push new WalletPairingProgressDialogViewController(request: request)
    @_request.on 'sendChallenge', onSendChallenge

  onShow: ->
    super

  onDismiss: ->
    super
    @_request?.off 'sendChallenge', @_onSendChallenge
    @_request?.cancel()

  _onSendChallenge: ->
    request = @_request
    @_request = null
    @getDialog().push new WalletPairingProgressDialogViewController(request: request)