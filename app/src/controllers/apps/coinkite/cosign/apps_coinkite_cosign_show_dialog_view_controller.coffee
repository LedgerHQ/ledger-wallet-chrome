class @AppsCoinkiteCosignShowDialogViewController extends DialogViewController

  show: ->
    transaction = Bitcoin.Transaction.deserialize(@params.request.raw_unsigned_txn)
    @amount = transaction.outs[0].value
    @address = transaction.outs[0].address.toString()
    super

  confirm: ->
    dialog = new AppsCoinkiteCosignSigningDialogViewController(request: @params.request, ck: @params.ck)
    @getDialog().push dialog