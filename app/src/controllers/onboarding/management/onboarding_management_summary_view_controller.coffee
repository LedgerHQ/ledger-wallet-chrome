class @OnboardingManagementSummaryViewController extends @OnboardingViewController

  navigation:
    continueUrl: '/onboarding/management/provisioning'

  navigationContinueParams: ->
    dongle_mode: @params.dongle_mode
    back: @representativeUrl()
    pin: @params.pin
    rootUrl: @params.rootUrl
    seed: @params.seed