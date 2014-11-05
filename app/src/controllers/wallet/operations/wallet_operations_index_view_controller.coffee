class @WalletOperationsIndexViewController extends ViewController

  onBeforeRender: ->
    @account = {
      name: @params.account_name
    }
    @displayAllAccount = not @params.account_name?

  onAfterRender: ->
    @select('#sort-order').selectric()

  showOperation: (params) ->
    dialog = new WalletOperationsDetailDialogViewController(params)
    dialog.show()