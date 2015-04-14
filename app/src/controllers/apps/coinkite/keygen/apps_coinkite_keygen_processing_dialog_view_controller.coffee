class @AppsCoinkiteKeygenProcessingDialogViewController extends @DialogViewController

  view:
    contentContainer: '#content_container'
    
  onAfterRender: ->
    super
    @view.spinner = ledger.spinners.createLargeSpinner(@view.contentContainer[0])
    ck = new Coinkite()
    ck.getExtendedPublickey (result, error) =>
      if error?
        @dismiss =>
          dialog = new CommonDialogsMessageDialogViewController(kind: "error", title: t("apps.coinkite.keygen.errors.derivation_failed"), error)
          dialog.show()
      else
        @getDialog().push new AppsCoinkiteKeygenShowDialogViewController(xpub: result.xpub, signature: result.signature)
