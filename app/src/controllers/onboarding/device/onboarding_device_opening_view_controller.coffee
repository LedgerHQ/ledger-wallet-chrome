class @OnboardingDeviceOpeningViewController extends @OnboardingViewController

  onAfterRender: ->
    super
    @view.spinner = ledger.spinners.createLargeSpinner(@select('div.greyed-container')[0])
    setTimeout =>
      ledger.app.router.go '/wallet/dashboard/index'
    , 1000

  openSupport: ->
    window.open t 'application.support_url'