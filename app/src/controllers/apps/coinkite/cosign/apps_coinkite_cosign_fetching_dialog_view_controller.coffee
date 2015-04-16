class @AppsCoinkiteCosignFetchingDialogViewController extends @DialogViewController

  view:
    contentContainer: '#content_container'
    
  onAfterRender: ->
    super
    @view.spinner = ledger.spinners.createLargeSpinner(@view.contentContainer[0])
    request = @params.request
    Coinkite.factory (ck) =>
      if ck?
        ck.getRequestData request, (data, error) =>
          if error?
            @dismiss =>
              dialog = new CommonDialogsMessageDialogViewController(kind: "error", title: t("apps.coinkite.cosign.errors.coinkite_api"), subtitle: error)
              dialog.show()          
          else
            setTimeout ( =>
              ck.getCosigner data, (cosigner, signed) =>
                if cosigner?
                  if signed
                    @dismiss =>
                      dialog = new CommonDialogsMessageDialogViewController(kind: "success", title: t("apps.coinkite.cosign.signing.success"), subtitle: t("apps.coinkite.cosign.signing.already_signed"))
                      dialog.show()                    
                  else
                    ck.getCosignData request, cosigner, (data, error) =>
                      if error?
                        @dismiss =>
                          dialog = new CommonDialogsMessageDialogViewController(kind: "error", title: t("apps.coinkite.cosign.errors.coinkite_api"), subtitle: error)
                          dialog.show()
                      else
                        @dismiss =>
                          dialog = new AppsCoinkiteCosignShowDialogViewController(request: data, ck: ck)
                          dialog.show()
                else
                  @dismiss =>
                    dialog = new CommonDialogsMessageDialogViewController(kind: "error", title: t("apps.coinkite.cosign.errors.wrong_nano"), subtitle: t("apps.coinkite.cosign.errors.wrong_nano_text"))
                    dialog.show()
            ), 2000  # rate limiting 2s on Coinkite
      else
        @dismiss =>
          dialog = new CommonDialogsMessageDialogViewController(kind: "error", title: t("apps.coinkite.cosign.errors.missing_api_key"), subtitle: t("apps.coinkite.cosign.errors.missing_api_key_text"))
          dialog.show()              