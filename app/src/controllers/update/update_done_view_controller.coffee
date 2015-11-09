class @UpdateDoneViewController extends @UpdateViewController

  localizablePageSubtitle: "update.done.update_succeeded"
  localizableNextButton: "common.restore"
  navigation:
    nextRoute: "/onboarding/device/connecting"

  navigateNext: ->
    @getRequest().cancel()
    ledger.app.reconnectDongleAndEnterWalletMode().then =>
      super