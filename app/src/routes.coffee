# routes that do not need a plugged ledger wallet
ledger.router ?= {}
ledger.router.ignorePluggedWalletForRouting = yes
ledger.router.pluggedWalletRoutesExceptions = [
  '/',
  '/onboarding/device/plug'
]

# routes declarations
@declareRoutes = (route, app) ->
  ## Default
  route '/', ->
    app.router.go '/wallet/accounts/0/show', {animateIntro: yes}

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
  route '/onboarding/management/security', (params) ->
    app.navigate ONBOARDING_LAYOUT, OnboardingManagementSecurityViewController

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
  # Accounts
  route '/wallet/accounts/{id}/show', (params) ->
    app.navigate WALLET_LAYOUT, WalletAccountsShowViewController

  # Send
  route '/wallet/send/index', (params) ->
    dialog = new WalletSendIndexDialogViewController()
    dialog.show()

  route '/wallet/send/validation', (params) ->
    dialog = new WalletSendValidationDialogViewController()
    dialog.show()

  # Receive
  route '/wallet/receive/index', (params) ->
    dialog = new WalletReceiveIndexDialogViewController()
    dialog.show()

  # Help
  route '/wallet/help/index', (params) ->
    window.open t 'application.support_url'

  # Operations
  route '/wallet/accounts/operations/index', (params) ->
    app.navigate WALLET_LAYOUT, WalletOperationsIndexViewController
