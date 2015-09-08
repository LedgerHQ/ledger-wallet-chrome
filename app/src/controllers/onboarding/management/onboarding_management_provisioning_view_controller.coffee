class @OnboardingManagementProvisioningViewController extends @OnboardingViewController

  onAfterRender: ->
    super
    @view.spinner = ledger.spinners.createLargeSpinner(@select('div.greyed-container')[0])
    if ledger.app.dongle.getFirmwareInformation().hasSubFirmwareSupport()
      @_performSetup()
    else
      @_performLegacySetup()

  _performLegacySetup: ->
    ledger.app.dongle.deprecatedSetup @params.pin, ledger.bitcoin.bip39.mnemonicPhraseToSeed(@params.mnemonicPhrase)
    .then => ledger.wallet.checkSetup ledger.app.dongle, @params.seed, @params.pin
    .then =>
      ledger.app.router.go '/onboarding/management/done', {wallet_mode: @params.wallet_mode}
    .fail =>
      ledger.app.router.go '/onboarding/management/done', {wallet_mode: @params.wallet_mode, error: 1}

  _performSetup: ->
    ledger.app.dongle.deprecatedSetup @params.pin, ledger.bitcoin.bip39.mnemonicPhraseToSeed(@params.mnemonicPhrase)
    .then =>
      ledger.app.router.go '/onboarding/management/switch_firmware', _.extend(_.clone(@params), mode: 'operation', pin: @params.pin, on_done: ledger.url.createUrlWithParams('/onboarding/management/done', wallet_mode: @params.wallet_mode))
      return
    .fail =>
      if @params.retrying? is false
        params = _.clone @params
        _.extend params, retrying: yes
        ledger.app.router.go '/onboarding/management/switch_firmware', _.extend(_.clone(@params), mode: 'setup', pin: @params.pin, on_done: ledger.url.createUrlWithParams('/onboarding/management/provisioning', params))
      else
        ledger.app.router.go '/onboarding/management/done', {wallet_mode: @params.wallet_mode, error: 1}