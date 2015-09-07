class @OnboardingManagementProvisioningViewController extends @OnboardingViewController

  onAfterRender: ->
    super
    @view.spinner = ledger.spinners.createLargeSpinner(@select('div.greyed-container')[0])
    ledger.app.dongle.deprecatedSetup @params.pin, ledger.bitcoin.bip39.mnemonicPhraseToSeed(@params.mnemonicPhrase)
    .then => ledger.wallet.checkSetup ledger.app.dongle, @params.seed, @params.pin
    .then =>
      ledger.app.router.go '/onboarding/management/done', {wallet_mode: @params.wallet_mode}
    .fail =>
      ledger.app.router.go '/onboarding/management/done', {wallet_mode: @params.wallet_mode, error: 1}