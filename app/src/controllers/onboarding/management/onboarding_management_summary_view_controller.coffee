class @OnboardingManagementSummaryViewController extends @OnboardingViewController

  navigation:
    continueUrl: '/onboarding/management/provisioning'


  initialize: ->
    super
    if @params.swapped_bip39
      @navigation.continueUrl = '/onboarding/management/swapped_bip39_provisioning'

  navigationContinueParams: ->
    pin: @params.pin
    mnemonicPhrase: @params.mnemonicPhrase