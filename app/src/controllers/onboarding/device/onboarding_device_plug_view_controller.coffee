class @OnboardingDevicePlugViewController extends @OnboardingViewController

  _spinner: null

  onAfterRender: ->
    super
    @_spinner = ledger.spinners.createLargeSpinner(@select('div.greyed-container')[0])