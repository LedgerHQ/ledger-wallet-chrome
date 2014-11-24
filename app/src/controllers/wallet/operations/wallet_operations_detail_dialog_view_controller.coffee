class @WalletOperationsDetailDialogViewController extends DialogViewController

  show: ->
    Operation.findByUid(@params.operationUid).get (operation) =>
      @operation = operation
      @operation.senders = JSON.parse operation.senders
      @operation.recipients = JSON.parse operation.recipients
      super