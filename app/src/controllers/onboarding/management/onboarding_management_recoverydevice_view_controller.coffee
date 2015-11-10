class @OnboardingManagementRecoverydeviceViewController extends @OnboardingViewController

  bumpsStepCount: false

  navigateConvert: ->
    @navigateContinue('/onboarding/management/convert', message_mode: 'new')

  navigatePin: ->
    @navigateContinue('/onboarding/management/pin')