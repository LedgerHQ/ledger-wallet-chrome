class @AppsCoinkiteKeygenProcessingDialogViewController extends @DialogViewController

  cancellable: no

  view:
    contentContainer: '#content_container'
    
  onAfterRender: ->
    super
    @view.spinner = ledger.spinners.createLargeSpinner(@view.contentContainer[0])
    ck = new Coinkite()
    ck.getExtendedPublicKey @params.index, (result, error) =>
      return if not @isShown()
      if error?
        @dismiss =>
          dialog = new CommonDialogsMessageDialogViewController(kind: "error", title: t("apps.coinkite.keygen.errors.derivation_failed"), subtitle: error)
          dialog.show()
          if @params.api
            Api.callback_cancel 'coinkite_get_xpubkey', t('apps.coinkite.keygen.errors.derivation_failed')
      else
        if @params.api
          @dismiss =>
            Api.callback_success('coinkite_get_xpubkey', {xpubkey: result.xpub, signature: result.signature, path: result.path, index: @params.index})
            dialog = new CommonDialogsMessageDialogViewController(kind: "success", title: t("wallet.xpubkey.errors.derivation_successfull"))
            dialog.show()
        else
          @getDialog().push new AppsCoinkiteKeygenShowDialogViewController(xpub: result.xpub, signature: result.signature)

  cancel: ->
    @dismiss =>
      if @params.api
        Api.callback_cancel 'coinkite_get_xpubkey', t("apps.coinkite.keygen.errors.cancelled")
