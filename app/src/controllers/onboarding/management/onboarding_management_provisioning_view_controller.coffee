class @OnboardingManagementProvisioningViewController extends @OnboardingViewController

  onAfterRender: ->
    super
    @view.spinner = ledger.spinners.createLargeSpinner(@select('div.greyed-container')[0])
    ledger.app.wallet.setup @params.pin, @params.seed, (success) =>
      setTimeout =>
        ledger.app.router.go '/onboarding/management/done', if success then {wallet_mode: @params.wallet_mode} else {wallet_mode: @params.wallet_mode, error: 1}
      , 3000