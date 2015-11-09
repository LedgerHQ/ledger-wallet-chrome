class @OnboardingManagementRecoverymodeViewController extends @OnboardingViewController

    navigateConvert: ->
      @navigateContinue('/onboarding/management/convert', message_mode: 'old')

    navigateRecoveryDevice: ->
      @navigateContinue('/onboarding/management/recovery_device')