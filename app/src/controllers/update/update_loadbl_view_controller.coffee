class @UpdateLoadblViewController extends UpdateViewController

  view:
    progressFrame: "#progress"
    versionText: "#version"

  constructor: ->
    super

  _updateUi: ->
    @view.versionText.text("from #{@getRequest().getDongleVersion()} to #{@getRequest().getTargetVersion()}")

  onAfterRender: ->
    super
    @_updateUi()

  approveUpdate: ->
    @getRequest().approveCurrentState()
    @_updateUi()

  onNeedsUserApproval: -> @_updateUi()

  onProgress: (state, current, total) ->
    super
    @view.progressFrame.text("#{Math.ceil(current * 100 / total)}%")
