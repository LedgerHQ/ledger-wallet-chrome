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
    ledger.app.dongle.getState (state) =>
      if state == ledger.dongle.States.LOCKED
        ledger.app.router.go '/onboarding/device/pin'
      else
        ledger.app.router.go '/onboarding/management/welcome'

  navigateError: ->
    ledger.app.router.go '/onboarding/device/forged'

  _listenEvents: ->
    if ledger.app.dongle?
      ledger.app.dongle.isCertified (__, error) =>
        return unless ledger.app.dongle?
        unless error?
          do @navigateContinue
        else
          do @navigateError
    else
      ledger.app.once 'dongle:connected', => do @navigateContinue
      ledger.app.once 'dongle:forged', => do @navigateError