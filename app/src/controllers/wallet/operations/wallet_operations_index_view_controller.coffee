class @WalletOperationsIndexViewController extends ViewController

  onBeforeRender: ->
    @account = {
      name: @params.account_name
    }
    @displayAllAccount =  @params.account_name?

  showOperation: (params) ->
    dialog = new WalletOperationsDetailDialogViewController(params)
    dialog.show()