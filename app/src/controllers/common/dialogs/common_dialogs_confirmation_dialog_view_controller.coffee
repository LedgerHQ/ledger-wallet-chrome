class @CommonDialogsConfirmationDialogViewController extends ledger.common.DialogViewController

  positiveLocalizableKey: 'common.yes'
  positiveText: null
  negativeLocalizableKey: 'common.no'
  negativeText: null
  cancelLocalizableKey: 'common.cancel'
  titleLocalizableKey: 'common.confirmation'
  messageLocalizableKey: null
  message: null
  showsCancelButton: no
  restrainsDialogWidth: yes
  dismissAfterClick: yes

  constructor: ({message, positiveText, negativeText} = {}) ->
    super
    @setMessageLocalizableKey(message) if message?
    @positiveLocalizableKey = positiveText if positiveText?
    @negativeLocalizableKey = negativeText if negativeText?

  clickPositive: ->
    @emit 'click:positive'
    do @dismiss if @dismissAfterClick

  clickNegative: ->
    @emit 'click:negative'
    do @dismiss if @dismissAfterClick

  clickCancel: ->
    @emit 'click:cancel'
    do @dismiss if @dismissAfterClick

  setMessageLocalizableKey: (key) ->
    @messageLocalizableKey = key