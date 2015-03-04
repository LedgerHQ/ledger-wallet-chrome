class @UpdateErasingViewController extends UpdateViewController

  view:
    eraseSeedButton: "#eraseSeed"

  constructor: ->
    super
    @_onNeedsUserApproval = @_onNeedsUserApproval.bind(@)

  _updateUi: ->
    if @getRequest().isNeedingUserApproval()
      @view.eraseSeedButton.show()
    else
      @view.eraseSeedButton.hide()

  onAfterRender: ->
    super
    @_updateUi()

  onAttach: ->
    @getRequest().on 'needsUserApproval', @_onNeedsUserApproval

  onDetach: ->
    @getRequest().off 'needsUserApproval', @_onNeedsUserApproval

  approveSeedErasure: -> @getRequest().approveCurrentState()

  _onNeedsUserApproval: -> @_updateUi()

