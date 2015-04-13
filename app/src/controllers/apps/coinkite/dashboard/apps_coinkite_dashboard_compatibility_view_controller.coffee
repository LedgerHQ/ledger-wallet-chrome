class @AppsCoinkiteDashboardCompatibilityDialogViewController extends @DialogViewController

  view:
    contentContainer: '#content_container'
    
  onAfterRender: ->
    super
    @view.spinner = ledger.spinners.createLargeSpinner(@view.contentContainer[0])
    ck = new Coinkite()
    ck.testDongleCompatibility (success) =>
      if success
        @dismiss =>
          dialog = new CommonDialogsMessageDialogViewController(kind: "success", title: t("apps.coinkite.dashboard.compatibility.success"), subtitle: t("apps.coinkite.dashboard.compatibility.success_text"))
          dialog.show()
      else
        @dismiss =>
          dialog = new CommonDialogsMessageDialogViewController(kind: "error", title: t("apps.coinkite.dashboard.compatibility.fail"), subtitle: t("apps.coinkite.dashboard.compatibility.fail_text"))
          dialog.show()
