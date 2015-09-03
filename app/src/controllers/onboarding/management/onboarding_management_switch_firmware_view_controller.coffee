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

  _onProgress: (state, current, total) ->
    progress = current / total
    @view.progressLabel.text("#{Math.ceil(progress * 100)}%")
    @view.progressBar.setProgress progress

  _onUpdateNeedsUserApproval: -> @_request.approveCurrentState()