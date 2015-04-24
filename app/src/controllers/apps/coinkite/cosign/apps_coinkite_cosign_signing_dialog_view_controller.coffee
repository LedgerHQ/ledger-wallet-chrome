class @AppsCoinkiteCosignSigningDialogViewController extends @DialogViewController

  cancellable: no

  view:
    contentContainer: '#content_container'

  cancel: ->
    @dismiss =>
      if @params.request.api
        Api.callback_cancel 'coinkite_sign_json', t("apps.coinkite.cosign.errors.request_cancelled")
    
  onAfterRender: ->
    super
    @view.spinner = ledger.spinners.createLargeSpinner(@view.contentContainer[0])
    if @params.request.api
      json = @params.ck.buildSignedJSON @params.request, (data, error) =>
        return if not @isShown()
        if error?
          Api.callback_cancel 'coinkite_sign_json', error
          @dismiss =>
            dialog = new CommonDialogsMessageDialogViewController(kind: "error", title: t("apps.coinkite.cosign.errors.signature_failed"), subtitle: error)
            dialog.show()          
        else
          if @params.request.post
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
            @dismiss =>
              Api.callback_success 'coinkite_sign_json', { json: data }
              dialog = new CommonDialogsMessageDialogViewController(kind: "success", title: t("apps.coinkite.cosign.signing.success"), subtitle: t("apps.coinkite.cosign.signing.success_info"))
              dialog.show()
    else
      @params.ck.cosignRequest @params.request, (data, error) =>
        if error?
          @dismiss =>
            dialog = new CommonDialogsMessageDialogViewController(kind: "error", title: t("apps.coinkite.cosign.errors.signature_failed"), subtitle: error)
            dialog.show()          
        else
          @dismiss =>
            dialog = new CommonDialogsMessageDialogViewController(kind: "success", title: t("apps.coinkite.cosign.signing.success"), subtitle: data.message)
            dialog.show()