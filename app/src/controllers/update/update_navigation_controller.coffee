class @UpdateNavigationController extends @NavigationController

  onAttach: ->
    @_request = ledger.fup.FirmwareUpdater.instance.requestFirmwareUpdate()
    @_request.on 'plug', => @_onPlugDongle()
    @_request.on 'unplug', =>  @_onDongleNeedPowerCycle()
    @_request.on 'stateChanged', (ev, data) => @_onStateChanged(data.newState, data.oldState)

    ledger.fup.FirmwareUpdater.instance.load =>

    window.fup = @_request # TODO: REMOVE THIS

  onDetach: ->
    @_request.cancel()

  _onPlugDongle: ->
    ledger.app.router.go '/update/plug'

  _onErasingDongle: ->
    ledger.app.router.go '/update/erasing'

  _onDongleNeedPowerCycle: ->
    ledger.app.router.go '/update/unplug'

  _onStateChanged: (newState, oldState) ->
    if newState is ledger.fup.FirmwareUpdateRequest.States.Erasing
      @_onErasingDongle()