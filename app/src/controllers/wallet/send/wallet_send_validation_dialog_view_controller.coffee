class @WalletSendValidationDialogViewController extends @DialogViewController

  view:
    cardContainer: "#card_container"
    enteredCode: "#entered_code"
    validationIndication: "#validation_indication"
    keycard: undefined
    tinyPincode: undefined

  onAfterRender: ->
    super
    @view.keycard = new ledger.pin_codes.KeyCard()
    @view.tinyPincode = new ledger.pin_codes.TinyPinCode()
    @view.keycard.insertIn @view.cardContainer[0]
    @view.tinyPincode.insertIn @view.enteredCode[0]
    @_listenEvents()
    @view.keycard.setValidableValues ['c', 'F', '5', 'G', 'q', '6', '1'] #@params.transaction.getKeycardIndexes()
    @view.tinyPincode.setInputsCount 7

  onShow: ->
    super
    @view.keycard.stealFocus()

  _listenEvents: ->
    @view.keycard.once 'completed', (event, value) =>
      @once 'dismiss', =>
        dialog = new WalletSendProcessingDialogViewController transaction: @params.transaction, keycode: value
        dialog.show()
      @dismiss()
    @view.keycard.on 'character:input', (event, value) =>
      @view.tinyPincode.setValuesCount @view.keycard.value().length
    @view.keycard.on 'character:waiting', (event, value) =>

    @once 'dismiss', =>
      @view.keycard.off 'completed'
      @view.keycard.off 'character:input'
      @view.keycard.off 'character:waiting'
