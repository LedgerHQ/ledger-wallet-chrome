class @OnboardingDeviceConnectingViewController extends @OnboardingViewController

  defaultParams:
    animateIntro: no
  view:
    currentAction: "#current_action"
  timer: null

  onAfterRender: ->
    super
    @_listenEvents()
    @view.spinner = ledger.spinners.createLargeSpinner(@select('div.greyed-container')[0])
    @view.currentAction.text(t 'onboarding.device.connecting.is_connecting')
    @_launchAttestation()

  openSupport: ->
    window.open t 'application.support_url'

  onDetach: ->
    super
    ledger.app.off 'dongle:connected'
    ledger.app.off 'dongle:forged'
    ledger.app.off 'dongle:communication_error'
    @_stopTimer()

  _navigateContinue: ->
    @_stopTimer()
    ledger.app.wallet?.isFirmwareUpdateAvailable (isAvailable) =>
      if isAvailable
        ledger.app.router.go '/onboarding/device/update'
      else
        ledger.app.wallet.getState (state) =>
          if state == ledger.wallet.States.LOCKED
            ledger.app.router.go '/onboarding/device/pin'
          else
            ledger.app.router.go '/onboarding/management/welcome'

  _navigateForged: ->
    @_stopTimer()
    ledger.app.wallet?.isDongleBetaCertified (__, error) =>
      if error?
        ledger.app.router.go '/onboarding/device/forged'
      else
        ledger.app.wallet?.isFirmwareOverwriteOrUpdateAvailable (isAvailable) =>
          if isAvailable and not ledger.fup.versions.Nano.CurrentVersion.Beta
            ledger.app.setExecutionMode(ledger.app.Modes.FirmwareUpdate)
            ledger.app.router.go '/update/index', {hidePreviousButton: yes}
          else
            @_navigateContinue()

  _navigateError: ->
    @_stopTimer()
    ledger.app.router.go '/onboarding/device/failed'

  _listenEvents: ->
    ledger.app.once 'dongle:connected', => @_navigateContinue()
    ledger.app.once 'dongle:forged', => @_navigateForged()
    ledger.app.once 'dongle:communication_error', => @_navigateError()

  _stopTimer: ->
    if @timer?
      clearTimeout @timer
      @timer = null

  _launchAttestation: ->
    if ledger.app.wallet?
      ledger.app.performDongleAttestation()
    @timer = setTimeout =>
      # attestation timed out
      @_navigateError()
    , 30000