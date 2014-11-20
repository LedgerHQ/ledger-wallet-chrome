class @OnboardingDeviceOpeningViewController extends @OnboardingViewController

  view:
    currentAction: "#current_action"

  onAfterRender: ->
    super
    @view.spinner = ledger.spinners.createLargeSpinner(@select('div.greyed-container')[0])
    if Wallet.instance?.isInitialized
      ledger.app.router.go '/wallet/accounts/0/show'
    else
      @view.currentAction.text t 'onboarding.device.opening.is_opening'
      ledger.app.on 'wallet:initialized', =>
        ledger.app.router.go '/wallet/accounts/0/show'
      ledger.app.on 'wallet:initialization:creation', =>
        @view.currentAction.text t 'onboarding.device.opening.is_synchronizing'

  openSupport: ->
    window.open t 'application.support_url'