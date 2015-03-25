class @WalletPairingIndexDialogViewController extends DialogViewController

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
      return if not error?
      @_request = null
      @once 'dismiss', =>
        # show error
        dialog = new CommonDialogsMessageDialogViewController(kind: "error", title: t("wallet.pairing.errors.pairing_failed"), subtitle: t("wallet.pairing.errors." + error))
        dialog.show()
      @dismiss()

  onDetach: ->
    super
    @_request?.off 'sendChallenge', @_onSendChallenge

  onDismiss: ->
    super
    @_request?.cancel()

  openSupport: ->
    window.open t 'application.support_url'

  _onSendChallenge: ->
    request = @_request
    @_request?.off 'sendChallenge', @_onSendChallenge
    @_request = null
    @getDialog().push new WalletPairingProgressDialogViewController(request: request)