class @UpdateUpdatingViewController extends UpdateViewController

  navigation:
    nextRoute: "/update/loading"
  localizablePageSubtitle: "update.updating.update_confirmation"
  localizableNextButton: "common.update"

  navigateNext: ->
    @getRequest().approveCurrentState()
    super

  onBeforeRender: ->
    super
    @dongleVersion = @getRequest().getDongleVersion()
    @targetVersion = @getRequest().getTargetVersion()