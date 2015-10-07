class @OnboardingManagementProvisioningViewController extends @OnboardingViewController

  onAfterRender: ->
    super
    @view.spinner = ledger.spinners.createLargeSpinner(@select('div.greyed-container')[0])
    if ledger.app.dongle.getFirmwareInformation().hasSubFirmwareSupport()
      @_performSetup()
    else
      @_performLegacySetup()

  _performLegacySetup: ->
    seed = ledger.bitcoin.bip39.mnemonicPhraseToSeed(@params.mnemonicPhrase)
    ledger.app.dongle.setup @params.pin, seed
    .then =>
      ledger.wallet.checkSetup ledger.app.dongle, seed, @params.pin
    .then =>
      ledger.app.router.go '/onboarding/management/done', {wallet_mode: @params.wallet_mode}
    .fail =>
      ledger.app.router.go '/onboarding/management/done', {wallet_mode: @params.wallet_mode, error: 1}
