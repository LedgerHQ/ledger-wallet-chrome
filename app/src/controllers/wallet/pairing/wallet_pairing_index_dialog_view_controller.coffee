class @WalletPairingIndexDialogViewController extends DialogViewController

  initialize: ->
    super

  onAfterRender: ->
    super
    [pairingId, promise] = ledger.m2fa.pairDevice()
    @view.qrcode = new QRCode "qrcode_frame",
        text: pairingId
        width: 196
        height: 196
        colorDark : "#000000"
        colorLight : "#ffffff"
        correctLevel : QRCode.CorrectLevel.H

  onShow: ->
    super

  dismiss: ->
    super
    pr