class @UpdateUpdatingViewController extends UpdateViewController

  navigation:
    nextRoute: ""
  view:
    keycardErasureSection: '#keycard-erasure-section'
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

  onAfterRender: ->
    super
    if @params?.no_erase_keycard_seed is true
      @view.keycardErasureSection.remove()

