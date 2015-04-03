class @CommonDialogsConfirmationDialogViewController extends @DialogViewController

  positiveLocalizableKey: 'common.yes'
  negativeLocalizableKey: 'common.no'
  titleLocalizableKey: 'common.confirmation'
  messageLocalizableKey: null

  clickPositive: ->
    @emit 'click:positive'
    do @dismiss

  clickNegative: ->
    @emit 'click:negative'
    do @dismiss

  setMessageLocalizableKey: (key) ->
    @messageLocalizableKey = key