class @UpdateReloadblfromosViewController extends UpdateViewController

  view:
    startButton: "#start"
    defaultFrame: "#default"
    progressFrame: "#progress"
    versionText: "#version"

  constructor: ->
    super

  _updateUi: ->
    @view.versionText.text("from #{@getRequest().getDongleVersion()} to #{@getRequest().getTargetVersion()}")
    if @getRequest().isNeedingUserApproval()
      @view.defaultFrame.show()
      @view.progressFrame.hide()
    else
      @view.defaultFrame.hide()
      @view.progressFrame.show()

  onAfterRender: ->
    super
    @view.progressFrame.hide()
    @_updateUi()

  approveUpdate: ->
    @getRequest().approveCurrentState()
    @_updateUi()

  onNeedsUserApproval: -> @_updateUi()

  onProgress: (state, current, total) ->
    super
    @view.progressFrame.text("#{Math.ceil(current * 100 / total)}%")
