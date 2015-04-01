class @UpdateUpdatingViewController extends UpdateViewController

  navigation:
    nextRoute: ""
  localizablePageSubtitle: "update.updating.update_confirmation"
  localizableNextButton: "common.update"

  navigateNext: ->
    if ledger.managers.system.isLinux() or ledger.managers.system.isUnknown()
      @navigation.nextRoute = "/update/linux"
    else
      @getRequest().approveCurrentState()
      @navigation.nextRoute = "/update/loading"
    super

  onBeforeRender: ->
    super
    @dongleVersion = @getRequest().getDongleVersion()
    @targetVersion = @getRequest().getTargetVersion()