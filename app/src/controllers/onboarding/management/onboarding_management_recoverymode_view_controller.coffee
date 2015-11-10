class @OnboardingManagementRecoverymodeViewController extends @OnboardingViewController

  bumpsStepCount: false

  navigateConvert: ->
    @navigateContinue('/onboarding/management/convert', message_mode: 'old')

  navigateRecoveryDevice: ->
    @navigateContinue('/onboarding/management/recovery_device')