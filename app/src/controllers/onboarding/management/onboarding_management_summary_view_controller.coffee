class @OnboardingManagementSummaryViewController extends @OnboardingViewController

  navigation:
    continueUrl: '/onboarding/management/provisioning'

  navigationContinueParams: ->
    wallet_mode: @params.wallet_mode
    back: @representativeUrl()
    pin: @params.pin
    rootUrl: @params.rootUrl
    seed: @params.seed