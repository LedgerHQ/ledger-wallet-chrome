class @CommonDialogsConfirmationDialogViewController extends @DialogViewController

  positiveLocalizableKey: 'common.dialogs.yes'
  negativeLocalizableKey: 'common.dialogs.no'
  titleLocalizableKey: 'common.dialogs.confirmation'

  clickPositive: ->
    @emit 'click:positive'
    do @dismiss

  clickNegative: ->
    @emit 'click:negative'
    do @dismiss

  setMessageLocalizableKey: (key) ->
    @messageLocalizableKey = key

  setAbstractLocalizableKey: (key) ->
    @abstractLocalizableKey = key