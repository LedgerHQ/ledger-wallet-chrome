class @OnboardingManagementRecoverydeviceViewController extends @OnboardingViewController

  navigateConvert: ->
    @navigateContinue('/onboarding/management/convert', message_mode: 'new')

  navigatePin: ->
    @navigateContinue('/onboarding/management/pin')