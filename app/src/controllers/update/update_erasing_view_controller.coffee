class @UpdateErasingViewController extends UpdateViewController

  localizableNextButton: "common.reset"
  localizablePageSubtitle: "update.erasing.erasure_confirmation"
  navigation:
    nextRoute: ""
    previousRoute: "/update/seed"
    previousParams: {animateIntro: no}

  render: ->
    super
    if @getRequest().getDongleFirmware().hasSubFirmwareSupport()
      @navigation.previousRoute = "/update/unlocking"



  navigateNext: ->
    @getRequest().forceDongleErasure()
    @getRequest().approveDongleErasure()