class @UpdateErasingViewController extends UpdateViewController

  localizableNextButton: "common.erase"
  localizablePageSubtitle: "update.erasing.erasure_confirmation"
  navigation:
    nextRoute: ""
    previousRoute: ""

  navigateNext: ->
    @getRequest().approveCurrentState()