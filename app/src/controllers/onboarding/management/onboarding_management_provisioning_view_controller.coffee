class @OnboardingManagementProvisioningViewController extends @OnboardingViewController

  onAfterRender: ->
    super
    @view.spinner = ledger.spinners.createLargeSpinner(@select('div.greyed-container')[0])
    ledger.app.dongle.setup @params.pin, @params.seed, (success) =>
      setTimeout =>
        ledger.app.router.go '/onboarding/management/done', if success then {dongle_mode: @params.dongle_mode} else {dongle_mode: @params.dongle_mode, error: 1}
      , 3000