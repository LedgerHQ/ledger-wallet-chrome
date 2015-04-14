class @AppsCoinkiteCosignSigningDialogViewController extends @DialogViewController

  view:
    contentContainer: '#content_container'
    
  onAfterRender: ->
    super
    @view.spinner = ledger.spinners.createLargeSpinner(@view.contentContainer[0])
    @params.ck.cosignTransaction @params.request, (data, error) =>
      if error?
        @dismiss =>
          dialog = new CommonDialogsMessageDialogViewController(kind: "error", title: t("apps.coinkite.cosign.errors.signature_failed"), subtitle: error)
          dialog.show()          
      else
        @dismiss =>
          dialog = new CommonDialogsMessageDialogViewController(kind: "success", title: t("apps.coinkite.cosign.signing.success"), subtitle: data.message)
          dialog.show()