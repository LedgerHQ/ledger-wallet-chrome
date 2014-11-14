class @OnboardingManagementProvisioningViewController extends @OnboardingViewController

  navigation:
    continueUrl: '/onboarding/management/done'

  initialize: ->
    super
    setTimeout =>
      do @navigateContinue
    , 3000

  navigationContinueParams: ->
    wallet_mode: @params.wallet_mode
    back: @representativeUrl()
    rootUrl: @params.rootUrl

  onAfterRender: ->
    super
    @view.spinner = ledger.spinners.createLargeSpinner(@select('div.greyed-container')[0])