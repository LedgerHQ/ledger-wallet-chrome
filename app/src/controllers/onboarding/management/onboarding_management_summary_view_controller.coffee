class @OnboardingManagementSummaryViewController extends @OnboardingViewController

  navigation:
    continueUrl: '/onboarding/management/provisioning'

  navigationContinueParams: ->
    pin: @params.pin
    seed: @params.seed