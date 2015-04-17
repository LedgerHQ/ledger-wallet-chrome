class @WalletSendCardDialogViewController extends @DialogViewController

  view:
    cardContainer: "#card_container"
    enteredCode: "#validation_code"
    validationIndication: "#validation_indication"
    validationSubtitle: "#validation_subtitle"
    otherValidationMethodsLabel: "#other_validation_methods"
    keycard: undefined
    tinyPincode: undefined
  _validationDetails: undefined

  cancel: ->
    Api.callback_cancel 'send_payment', t('wallet.send.errors.cancelled')
    @dismiss()
    
  onAfterRender: ->
    super
    @_setupUI()
    @_updateUI()
    _.defer =>
      @view.keycard.stealFocus()

  otherValidationMethods: ->
    return if @params.options?.hideOtherValidationMethods? is true
    dialog = new WalletSendMethodDialogViewController(transaction: @params.transaction)
    @getDialog().push dialog

  _setupUI: ->
    @view.keycard = new ledger.pin_codes.KeyCard()
    @view.tinyPincode = new ledger.pin_codes.TinyPinCode()
    @view.keycard.insertIn @view.cardContainer[0]
    @view.tinyPincode.insertIn @view.enteredCode[0]
    @view.otherValidationMethodsLabel.hide() if @params.options?.hideOtherValidationMethods? is true
    @_listenEvents()

  _listenEvents: ->
    @view.keycard.once 'completed', (event, value) =>
      @dismiss =>
        dialog = new WalletSendProcessingDialogViewController transaction: @params.transaction, keycode: value
        dialog.show()
    @view.keycard.on 'character:input', (event, value) =>
      @view.tinyPincode.setValuesCount @view.keycard.value().length
      @_validationDetails.localizedIndexes.splice(0, 1)
    @view.keycard.on 'character:waiting', (event, value) =>
      @_updateValidableIndication()

  _updateUI: ->
    @_validationDetails = @params.transaction.getValidationDetails()
    @_validationDetails = _.extend @_validationDetails, @_buildValidableSettings(@_validationDetails)
    @view.keycard.setValidableValues @_validationDetails.validationCharacters
    @view.tinyPincode.setInputsCount @_validationDetails.validationCharacters.length
    if @_validationDetails.needsAmountValidation
      @view.validationSubtitle.text t 'wallet.send.card.amount_and_address_to_validate'
    else
      @view.validationSubtitle.text t 'wallet.send.card.address_to_validate'

  _updateValidableIndication: ->
    return if @_validationDetails.localizedIndexes.length == 0
    index = @_validationDetails.localizedIndexes[0]
    value = @_validationDetails.localizedString.slice(0, index)
    value += '<mark>'
    value += @_validationDetails.localizedString[index]
    value += '</mark>'
    remainingIndex = @_validationDetails.localizedString.length - index - 1
    if remainingIndex > 0
      value += @_validationDetails.localizedString.slice(-remainingIndex)
    @view.validationIndication.html value

  _buildValidableSettings: (validationDetails) ->
    string = ''
    indexes = []
    decal = 0
    # add amount
    if validationDetails.needsAmountValidation
      value = ledger.formatters.fromValue(validationDetails.amount.text)
      # normalize value
      dotIndex = value.indexOf '.'
      if dotIndex == -1
        value += '.000'
      else
        numDecimalDigits = value.length - 1 - dotIndex
        value += _.str.repeat '0', 3 - numDecimalDigits
      string += value + ' BTC'
      indexes = indexes.concat validationDetails.amount.indexes[0]
      indexes = indexes.concat _.map(validationDetails.amount.indexes.slice(1), (num) => num + 1) # decalage virgule
      string += ' ' + t('wallet.send.card.to') + ' '
    # add address
    decal += string.length
    string += validationDetails.recipientsAddress.text
    indexes = indexes.concat _.map(validationDetails.recipientsAddress.indexes, (num) => num + decal)
    {localizedString: string, localizedIndexes: indexes}