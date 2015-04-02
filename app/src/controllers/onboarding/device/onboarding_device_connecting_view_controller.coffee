class @OnboardingDeviceConnectingViewController extends @OnboardingViewController

  defaultParams:
    animateIntro: no

  view:
    currentAction: "#current_action"

  onAfterRender: ->
    super
    do @_listenEvents
    @view.spinner = ledger.spinners.createLargeSpinner(@select('div.greyed-container')[0])
    @view.currentAction.text(t 'onboarding.device.connecting.is_connecting')

  openSupport: ->
    window.open t 'application.support_url'

  _hideContent: (hidden, animated = yes) ->
    @view.contentContainer.children().each (index, node) =>
      node = $(node)
      if hidden == yes
        node.fadeOut(if animated then 250 else 0)
      else
        node.fadeIn(if animated then 250 else 0)

  navigateContinue: ->
    ledger.app.wallet?.isFirmwareUpdateAvailable (isAvailable) =>
      if isAvailable
        ledger.app.router.go '/onboarding/device/update'
      else
        ledger.app.wallet.getState (state) =>
          if state == ledger.wallet.States.LOCKED
            ledger.app.router.go '/onboarding/device/pin'
          else
            ledger.app.router.go '/onboarding/management/welcome'

  navigateError: ->
    ledger.app.wallet?.isDongleBetaCertified (__, error) =>
      if error?
        ledger.app.router.go '/onboarding/device/forged'
      else
        ledger.app.wallet?.isFirmwareOverwriteOrUpdateAvailable (isAvailable) =>
          if isAvailable and not ledger.fup.versions.Nano.CurrentVersion.Beta
            ledger.app.setExecutionMode(ledger.app.Modes.FirmwareUpdate)
            ledger.app.router.go '/update/index', {hidePreviousButton: yes}
          else
            @navigateContinue()

  _listenEvents: ->
    if ledger.app.wallet?
      ledger.app.performDongleAttestation()
    ledger.app.once 'dongle:connected', => do @navigateContinue
    ledger.app.once 'dongle:forged', => do @navigateError