class @OnboardingDeviceOpeningViewController extends @OnboardingViewController

  view:
    currentAction: "#current_action"

  onAfterRender: ->
    super
    @view.spinner = ledger.spinners.createLargeSpinner(@select('div.greyed-container')[0])
    if Wallet.instance?.isInitialized
      ledger.app.router.go '/wallet/accounts/index'
    else
      @view.currentAction.text t 'onboarding.device.opening.is_opening'
      ledger.app.on 'wallet:initialized', @onWalletInitialized
      ledger.app.on 'wallet:initialization:creation', @onWalletIsSynchronizing


  openSupport: ->
    window.open t 'application.support_url'

  onWalletInitialized: -> ledger.app.router.go '/wallet/accounts/index'

  onWalletIsSynchronizing: -> @view.currentAction.text t 'onboarding.device.opening.is_synchronizing'

  onDetach: ->
    super
    ledger.app.off 'wallet:initialized', @onWalletInitialized
    ledger.app.off 'wallet:initialization:creation', @onWalletIsSynchronizing
