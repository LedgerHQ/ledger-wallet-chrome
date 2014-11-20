class @WalletSendValidationDialogViewController extends @DialogViewController

  view:
    cardContainer: "#card_container"
    enteredCode: "#entered_code"
    keycardCode: "#entered_code >.code"

  onAfterRender: ->
    super
    @view.keycard = new ledger.pin_codes.KeyCard()
    @view.keycard.setValidableValues ['c', 'A', '2']
    @view.keycard.insertIn @view.cardContainer[0]
    @view.enteredCode.hide()
    @_listenEvents()

  onShow: ->
    super
    @view.keycard.stealFocus()

  _listenEvents: ->
    @view.keycard.once 'completed', =>
      @once 'dismiss', =>
        dialog = new WalletSendProcessingDialogViewController()
        dialog.show()
      @dismiss()
    @view.keycard.on 'character', (event, value) =>
      @view.keycardCode.text _.str.pad('', value.length, '•')
      @view.enteredCode.show()
    @once 'dismiss', =>
      @view.keycard.off 'completed'
      @view.keycard.off 'character'