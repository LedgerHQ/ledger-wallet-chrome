@declareRoutes = (route, app) ->

  ## Default
  route '/', ->
    app.router.go '/onboarding/device/plug', {animateIntro: yes}

  ## Onboarding
  # Device
  route '/onboarding/device/plug', (params) ->
    app.navigate ONBOARDING_LAYOUT, OnboardingDevicePlugViewController

  route '/onboarding/device/unplug', (params) ->
    app.navigate ONBOARDING_LAYOUT, OnboardingDeviceUnplugViewController

  route '/onboarding/device/pin', (params) ->
    app.navigate ONBOARDING_LAYOUT, OnboardingDevicePinViewController

  route '/onboarding/device/frozen', (params) ->
    app.navigate ONBOARDING_LAYOUT, OnboardingDeviceFrozenViewController

  route '/onboarding/device/wrongpin', (params) ->
    app.navigate ONBOARDING_LAYOUT, OnboardingDeviceWrongpinViewController

  route '/onboarding/device/opening', (params) ->
    app.navigate ONBOARDING_LAYOUT, OnboardingDeviceOpeningViewController

  # Management
  route '/onboarding/management/done', (params) ->
    app.navigate ONBOARDING_LAYOUT, OnboardingManagementDoneViewController

  route '/onboarding/management/welcome', (params) ->
    app.navigate ONBOARDING_LAYOUT, OnboardingManagementWelcomeViewController

  route '/onboarding/management/pinconfirmation', (params) ->
    app.navigate ONBOARDING_LAYOUT, OnboardingManagementPinconfirmationViewController

  route '/onboarding/management/pin', (params) ->
    app.navigate ONBOARDING_LAYOUT, OnboardingManagementPinViewController

  route '/onboarding/management/seed', (params) ->
    app.navigate ONBOARDING_LAYOUT, OnboardingManagementSeedViewController

  route '/onboarding/management/summary', (params) ->
    app.navigate ONBOARDING_LAYOUT, OnboardingManagementSummaryViewController

  route '/onboarding/management/provisioning', (params) ->
    app.navigate ONBOARDING_LAYOUT, OnboardingManagementProvisioningViewController

  ## Wallet
  # Dashboard
  route '/wallet/dashboard/index', (params) ->
    app.navigate WALLET_LAYOUT, WalletDashboardIndexViewController

  route '/wallet/send/index', (params) ->


  route '/wallet/receive/index', (params) ->
    d = new WalletOperationsDetailDialogViewController()
    d.show()

  # Accounts
  route '/wallet/accounts/index', (params) ->
    app.navigate WALLET_LAYOUT, WalletAccountsAccountViewController

  # Operations
  route '/wallet/accounts/operations/index', (params) ->
    app.navigate WALLET_LAYOUT, WalletOperationsIndexViewController
