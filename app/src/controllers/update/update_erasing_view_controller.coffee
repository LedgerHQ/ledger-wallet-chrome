class @UpdateErasingViewController extends UpdateViewController

  view:
    eraseSeedButton: "#eraseSeed"
    defaultFrame: "#default"
    powerCycleFrame: "#powerCycle"
    remainingStepText: "#remainingStep"

  constructor: ->
    super
    @_onNeedsUserApproval = @_onNeedsUserApproval.bind(@)
    @_onErasureStep = @_onErasureStep.bind(@)

  _updateUi: ->
    if @getRequest().isNeedingUserApproval()
      @view.eraseSeedButton.show()
    else
      @view.eraseSeedButton.hide()

  onAfterRender: ->
    super
    @view.powerCycleFrame.hide()
    @_updateUi()

  onAttach: ->
    @getRequest().on 'erasureStep', @_onErasureStep

  onDetach: ->
    @getRequest().off 'erasureStep', @_onErasureStep

  approveSeedErasure: -> @getRequest().approveCurrentState()

  onNeedsUserApproval: -> @_updateUi()

  _onErasureStep: (ev, remainingStep) ->
    @view.defaultFrame.hide()
    @view.powerCycleFrame.show()
    @view.remainingStepText.text("Remaining: #{remainingStep}")