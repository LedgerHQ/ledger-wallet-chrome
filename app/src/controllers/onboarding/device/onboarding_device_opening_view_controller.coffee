class @OnboardingDeviceOpeningViewController extends @OnboardingViewController

  onAfterRender: ->
    super
    @view.spinner = ledger.spinners.createLargeSpinner(@select('div.greyed-container')[0])

  openSupport: ->
    window.open t 'application.support_url'