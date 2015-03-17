class @OnboardingManagementSecurityViewController extends @OnboardingViewController

  navigation:
    continueUrl: '/onboarding/management/pin'

  navigationContinueParams: ->
    dongle_mode: @params.dongle_mode
    rootUrl: @params.rootUrl
    back: @representativeUrl()
