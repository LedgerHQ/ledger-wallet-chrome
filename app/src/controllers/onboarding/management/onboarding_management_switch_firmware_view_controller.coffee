States = ledger.fup.FirmwareUpdateRequest.States

class @OnboardingManagementSwitchfirmwareViewController extends @OnboardingViewController

  view:
    progressLabel: "#progress"
    progressBarContainer: "#bar_container"

  constructor: ->
    super
    if @params.mode is 'setup'
      @_request = ledger.app.dongle.getFirmwareUpdater().requestSetupFirmwareUpdate()
    else
      @_request = ledger.app.dongle.getFirmwareUpdater().requestOperationFirmwareUpdate()
    @_request.onProgress @_onProgress.bind(@)
    @_request.on 'needsUserApproval', @_onUpdateNeedsUserApproval.bind(@)
    @_request.on 'stateChanged', (ev, data) => @_onStateChanged(data.newState, data.oldState)
    @_fup = ledger.app.dongle.getFirmwareUpdater()
    ledger.app.setExecutionMode(ledger.app.Modes.FirmwareUpdate)

  onAfterRender: ->
    super
    @view.progressBar = new ledger.progressbars.ProgressBar(@view.progressBarContainer)
    @view.progressBar.setAnimated(false)
    @_fup.load =>
      @_request.startUpdate()

  onDetach: ->
    @_request.cancel()
    @_fup.unload()
    ledger.app.setExecutionMode(ledger.app.Modes.Wallet)
    if @_request.getDongle()?
      ledger.app.reconnectDongle(@_request.getDongle())

  _onFirmwareSwitchDone: ->
    if @params.mode is 'setup'
      # Choose PIN...
      ledger.app.router.go '/onboarding/management/security'
    else
      # Congrats!

  _onProgress: (state, current, total) ->
    loadingBlProgress = if state is States.ReloadingBootloaderFromOs then current / total else 1
    loadingOsProgress = if state is States.LoadingOs then  current / total else (if state is States.InitializingOs then 1 else 0)
    progress = (loadingBlProgress + loadingOsProgress) / 2
    @view.progressLabel.text("#{Math.ceil(progress * 100)}%")
    @view.progressBar.setProgress progress

  _onUpdateNeedsUserApproval: -> @_request.approveCurrentState()

  _onStateChanged: (newState, oldState) ->
    switch newState
      when ledger.fup.FirmwareUpdateRequest.States.Done then @_onFirmwareSwitchDone()
