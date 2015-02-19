class @WalletPairingIndexDialogViewController extends DialogViewController

  initialize: ->
    super

  onAfterRender: ->
    super
    @_request = ledger.m2fa.requestPairing()
    @view.qrcode = new QRCode "qrcode_frame",
        text: pairingId
        width: 196
        height: 196
        colorDark : "#000000"
        colorLight : "#ffffff"
        correctLevel : QRCode.CorrectLevel.H

  onShow: ->
    super

  onDismiss: ->
    super
    @_request.cancel()
