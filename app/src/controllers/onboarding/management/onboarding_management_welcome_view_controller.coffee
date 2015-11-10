class @OnboardingManagementWelcomeViewController extends @OnboardingViewController

  bumpsStepCount: false

  onBeforeRender: ->
    super
    if ledger.app.dongle.getFirmwareInformation().hasSetupFirmwareSupport()
      @_isSwappedBip39FeatureEnabled = ledger.app.dongle.isSwappedBip39FeatureEnabled()

  createNewWallet: -> @navigateNextPage('create')

  restoreWallet: ->
    @navigateNextPage('recover')

  navigateNextPage: (mode) ->
    navigateToSecurityPage = =>
      @navigateContinue '/onboarding/management/security',
          wallet_mode: mode
          back: @representativeUrl()
          rootUrl: @representativeUrl()
          step: 1
          swapped_bip39: no

    navigateToFirstSwappedBip39Page = =>
      @navigateContinue (if mode is 'create' then '/onboarding/management/pin' else '/onboarding/management/recovery_mode'),
        wallet_mode: mode
        back: @representativeUrl()
        rootUrl: @representativeUrl()
        step: 1
        swapped_bip39: yes

    navigateToSwitchFirmwarePage = =>
      @navigateContinue '/onboarding/device/switch_firmware',
        mode: 'setup'
        wallet_mode: mode
        back: @representativeUrl()
        rootUrl: @representativeUrl()
        step: 1
        swapped_bip39: yes

    firmware = ledger.app.dongle.getFirmwareInformation()

    if !firmware.hasSubFirmwareSupport()
      navigateToSecurityPage()
    else if firmware.hasSetupFirmwareSupport()
      @_isSwappedBip39FeatureEnabled.then (enabled) =>
        if enabled
          # Do something
          navigateToFirstSwappedBip39Page()
        else
          navigateToSecurityPage()
      .done()
    else
      navigateToSwitchFirmwarePage()
