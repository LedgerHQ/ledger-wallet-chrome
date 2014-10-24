class @OnboardingDevicePlugViewController extends @ViewController

  _spinner: null

  onAfterRender: ->
    super
    @_spinner = ledger.spinners.createLargeSpinner(@select('div.greyed-container')[0])