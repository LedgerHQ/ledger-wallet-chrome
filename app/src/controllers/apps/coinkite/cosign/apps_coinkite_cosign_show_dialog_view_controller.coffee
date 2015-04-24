class @AppsCoinkiteCosignShowDialogViewController extends DialogViewController

  cancellable: no

  show: ->
    if @params.json?
      @params.ck = new Coinkite()
      @params.request = @params.ck.getRequestFromJSON JSON.parse(@params.json)
    transaction = Bitcoin.Transaction.deserialize(@params.request.raw_unsigned_txn)
    @amount = transaction.outs[0].value
    @address = transaction.outs[0].address.toString()
    super

  cancel: ->
    @dismiss =>
      if @params.request.api
        Api.callback_cancel 'coinkite_sign_json', t("apps.coinkite.cosign.errors.request_cancelled")

  confirm: ->
    dialog = new AppsCoinkiteCosignSigningDialogViewController(request: @params.request, ck: @params.ck)
    @getDialog().push dialog