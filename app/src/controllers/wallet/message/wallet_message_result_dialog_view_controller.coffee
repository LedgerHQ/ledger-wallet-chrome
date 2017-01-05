class @WalletMessageResultDialogViewController extends ledger.common.DialogViewController

  view:
    result: '#result'

  onAfterRender: ->
    super
    @view.result.val(
      "-----BEGIN BITCOIN SIGNED MESSAGE-----\n" +
      "#{@params.message}\n" +
      "-----BEGIN SIGNATURE-----\n" +
      "#{@params.address}\n" +
      "#{@params.signature}\n" +
      "-----END BITCOIN SIGNED MESSAGE-----\n"
    )
