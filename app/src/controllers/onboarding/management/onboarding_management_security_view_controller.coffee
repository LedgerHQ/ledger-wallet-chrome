class @OnboardingManagementSecurityViewController extends @OnboardingViewController

  navigation:
    continueUrl: '/onboarding/management/pin'

  navigationContinueParams: ->
    wallet_mode: @params.wallet_mode
    rootUrl: @params.rootUrl
    back: @representativeUrl()
