class @OnboardingManagementProvisioningViewController extends @OnboardingViewController

  navigation:
    continueUrl: '/onboarding/management/done'

  navigationContinueParams: ->
    wallet_mode: @params.wallet_mode
    back: @representativeUrl()
    rootUrl: @params.rootUrl

  onAfterRender: ->
    super
    @view.spinner = ledger.spinners.createLargeSpinner(@select('div.greyed-container')[0])
    ledger.app.wallet.setup @params.pin, @params.seed, (success) =>
      setTimeout =>
        do @navigateContinue
      , 3000