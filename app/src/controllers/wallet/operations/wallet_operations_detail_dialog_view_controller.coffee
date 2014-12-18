class @WalletOperationsDetailDialogViewController extends DialogViewController

  show: ->
    @operation = Operation.findById(parseInt(@params['operationId']))
    super

  openBlockchain: ->
    window.open 'https://blockchain.info/tx/' + @operation.get('hash')