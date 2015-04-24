class @WalletXpubkeyProcessingDialogViewController extends @DialogViewController

  view:
    contentContainer: '#content_container'
    
  onAfterRender: ->
    super
    @view.spinner = ledger.spinners.createLargeSpinner(@view.contentContainer[0])
    ledger.app.wallet.getExtendedPublicKey @params.path, (key, error) =>
      if error?
        Api.callback_cancel('get_xpubkey', t("wallet.xpubkey.errors.derivation_failed"))
        @dismiss =>
          dialog = new CommonDialogsMessageDialogViewController(kind: "error", title: t("wallet.xpubkey.errors.derivation_failed"), subtitle: error)
          dialog.show()
      else
        xpubkey = key._xpub58
        Api.callback_success('get_xpubkey', {xpubkey: xpubkey})
        @dismiss =>
          dialog = new CommonDialogsMessageDialogViewController(kind: "success", title: t("wallet.xpubkey.errors.derivation_successfull"))
          dialog.show()
