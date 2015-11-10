class @OnboardingManagementDoneViewController extends @OnboardingViewController

  bumpsStepCount: false

  openSupport: ->
    window.open t 'application.support_url'