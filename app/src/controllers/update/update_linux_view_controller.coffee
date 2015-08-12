class @UpdateLinuxViewController extends @UpdateViewController

  navigation:
    nextRoute: "/update/loading"
  localizablePageSubtitle: "update.linux.linux_users"

  navigateNext: ->
    @getRequest().approveCurrentState()
    super