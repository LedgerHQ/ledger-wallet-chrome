class @UpdateDoneViewController extends @UpdateViewController

  localizablePageSubtitle: "update.done.update_succeeded"
  localizableNextButton: "common.restore"
  navigation:
    nextRoute: "/onboarding/device/connecting"

  initialize: ->
    super
    if @params.provisioned
      @localizableNextButton = "common.continue"

  navigateNext: ->
    @getRequest().cancel()
    ledger.app.reconnectDongleAndEnterWalletMode().then =>
      super