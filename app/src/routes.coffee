@declareRoutes = (route, app) ->

  ## Default
  route '/', ->
    app.router.go '/onboarding/device/plug'

  ## Onboarding
  # Device
  route '/onboarding/device/plug', (params) ->
    app.navigate ONBOARDING_LAYOUT, OnboardingDevicePlugViewController
  route '/onboarding/device/unplug', (params) ->
    app.navigate ONBOARDING_LAYOUT, OnboardingDeviceUnplugViewController

  ## Wallet
  # Dashboard
  route '/wallet/dashboard/index:#action:', (params) ->
    app.navigate WALLET_LAYOUT, WalletDashboardIndexViewController

  # Accounts
  route '/wallet/accounts/index{#action}{?params}', (params) ->
    l 'Accounts'