@declareRoutes = (route, app) ->

  ## Default
  route '/', ->
    app.router.go '/wallet/accounts/index'

  ## Onboarding
  # Device
  route '/onboarding/device/plug', (params) ->
    app.navigate ONBOARDING_LAYOUT, OnboardingDevicePlugViewController

  route '/onboarding/device/unplug', (params) ->
    app.navigate ONBOARDING_LAYOUT, OnboardingDeviceUnplugViewController

  route '/onboarding/device/pin', (params) ->
    app.navigate ONBOARDING_LAYOUT, OnboardingDevicePinViewController

  # Management
  route '/onboarding/management/done', (params) ->
    app.navigate ONBOARDING_LAYOUT, OnboardingManagementDoneViewController

  route '/onboarding/management/welcome', (params) ->
    app.navigate ONBOARDING_LAYOUT, OnboardingManagementWelcomeViewController

  route '/onboarding/management/frozen', (params) ->
    app.navigate ONBOARDING_LAYOUT, OnboardingManagementFrozenViewController

  route '/onboarding/management/pinconfirmation', (params) ->
    app.navigate ONBOARDING_LAYOUT, OnboardingManagementPinconfirmationViewController

  route '/onboarding/management/pin', (params) ->
    app.navigate ONBOARDING_LAYOUT, OnboardingManagementPinViewController

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
