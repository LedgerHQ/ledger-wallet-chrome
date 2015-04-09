class @AppsCoinkiteCosignFetchingDialogViewController extends @DialogViewController

  view:
    contentContainer: '#content_container'
    
  onAfterRender: ->
    super
    console.log @params
    @view.spinner = ledger.spinners.createLargeSpinner(@view.contentContainer[0])
    request = @params.request
    Coinkite.factory (ck) =>
      if ck?
        ck.getRequestData request, (data, error) =>
          if error?
            console.log "ERROR"
            @dismis =>
              dialog = new CommonDialogsMessageDialogViewController(kind: "error", title: t("apps.coinkite.cosign.errors.coinkite_api"), subtitle: error)
              dialog.show()          
          else
            ck.getCosigner data, (cosigner) =>
              if cosigner?
                ck.getCosignData request, cosigner, (data, error) =>
                  if error?
                    @dismiss =>
                      dialog = new CommonDialogsMessageDialogViewController(kind: "error", title: t("apps.coinkite.cosign.errors.coinkite_api"), subtitle: error)
                      dialog.show()
                  else
                    console.log data
                    #@getDialog().push new AppsCoinkiteKeygenShowDialogViewController(xpub: result.xpub, signature: result.signature)
              else
                @dismiss =>
                  dialog = new CommonDialogsMessageDialogViewController(kind: "error", title: t("apps.coinkite.cosign.errors.wrong_nano"), subtitle: t("apps.coinkite.cosign.errors.wrong_nano_text"))
                  dialog.show()
      else
        @dismis =>
          dialog = new CommonDialogsMessageDialogViewController(kind: "error", title: t("apps.coinkite.cosign.errors.missing_api_key"), subtitle: t("apps.coinkite.cosign.errors.missing_api_key_text"))
          dialog.show()              