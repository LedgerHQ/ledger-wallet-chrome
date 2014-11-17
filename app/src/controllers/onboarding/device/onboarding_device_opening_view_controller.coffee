class @OnboardingDeviceOpeningViewController extends @OnboardingViewController

  onAfterRender: ->
    super
    @view.spinner = ledger.spinners.createLargeSpinner(@select('div.greyed-container')[0])
    if Wallet.instance?.isInitialized
      ledger.app.router.go '/wallet/dashboard/index'
    else
      ledger.app.on 'wallet:initialized', =>
        ledger.app.router.go '/wallet/dashboard/index'

  openSupport: ->
    window.open t 'application.support_url'