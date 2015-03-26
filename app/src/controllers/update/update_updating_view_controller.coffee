class @UpdateUpdatingViewController extends UpdateViewController

  navigation:
    nextRoute: ""
  localizablePageSubtitle: "update.updating.update_confirmation"
  localizableNextButton: "common.update"

  navigateNext: ->
    @getRequest().approveCurrentState()

  onBeforeRender: ->
    super
    @dongleVersion = @getRequest().getDongleVersion()
    @targetVersion = @getRequest().getTargetVersion()