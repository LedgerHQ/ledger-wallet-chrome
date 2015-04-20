class @AppsCoinkiteCosignSigningDialogViewController extends @DialogViewController

  view:
    contentContainer: '#content_container'
    
  onAfterRender: ->
    super
    @view.spinner = ledger.spinners.createLargeSpinner(@view.contentContainer[0])
    if @params.request.api
      json = @params.ck.buildSignedJSON @params.request, (data, error) =>
        if error?
          Api.callback_cancel 'coinkite_sign_json', error
          @dismiss =>
            dialog = new CommonDialogsMessageDialogViewController(kind: "error", title: t("apps.coinkite.cosign.errors.signature_failed"), subtitle: error)
            dialog.show()          
        else
          @params.ck.postSignedJSON data, (data, error) =>
            if error?
              Api.callback_cancel 'coinkite_sign_json', error
              @dismiss =>
                dialog = new CommonDialogsMessageDialogViewController(kind: "error", title: t("apps.coinkite.cosign.errors.signature_failed"), subtitle: error)
                dialog.show() 
            else
              @dismiss =>
                if data == "DONE"
                  Api.callback_success 'coinkite_sign_json', { message: t("apps.coinkite.cosign.signing.success_info") }
                  dialog = new CommonDialogsMessageDialogViewController(kind: "success", title: t("apps.coinkite.cosign.signing.success"), subtitle: t("apps.coinkite.cosign.signing.success_info"))
                else
                  Api.callback_cancel 'coinkite_sign_json', data
                  dialog = new CommonDialogsMessageDialogViewController(kind: "error", title: t("apps.coinkite.cosign.errors.signature_failed"), subtitle: data)
                dialog.show()       
    else
      @params.ck.cosignTransaction @params.request, (data, error) =>
        if error?
          @dismiss =>
            dialog = new CommonDialogsMessageDialogViewController(kind: "error", title: t("apps.coinkite.cosign.errors.signature_failed"), subtitle: error)
            dialog.show()          
        else
          @dismiss =>
            dialog = new CommonDialogsMessageDialogViewController(kind: "success", title: t("apps.coinkite.cosign.signing.success"), subtitle: data.message)
            dialog.show()