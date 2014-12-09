class @WalletOperationsDetailDialogViewController extends DialogViewController

  show: ->
    @operation = Operation.findById(parseInt(@params['operationId']))
    super