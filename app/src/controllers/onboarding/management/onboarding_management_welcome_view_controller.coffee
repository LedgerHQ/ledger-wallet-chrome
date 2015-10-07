class @OnboardingManagementWelcomeViewController extends @OnboardingViewController

  onBeforeRender: ->
    super

  createNewWallet: -> @navigateNextPage('create')

  restoreWallet: ->
    @navigateNextPage('restore')

  navigateNextPage: (mode) ->
    navigateToSecurityPage = (swappedBip39) =>
      ledger.app.router.go '/onboarding/management/security',
          wallet_mode: mode
          back: @representativeUrl()
          rootUrl: @representativeUrl()
          step: 1
          swapped_bip39: swappedBip39

    firmware = ledger.app.dongle.getFirmwareInformation()

    if !firmware.hasSubFirmwareSupport()
      navigateToSecurityPage(no)
    else if firmware.hasSetupFirmwareSupport()
      ledger.app.dongle.isSwappedBip39FeatureEnabled().then (enabled) =>
        if enabled
          # Do something
        else
          navigateToSecurityPage(yes)
      .done()
    else
      # Switch firmware
