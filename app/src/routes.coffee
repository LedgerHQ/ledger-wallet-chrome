@declareRoutes = (route, app) ->

  # Onboarding
  route '/onboarding/plug', (params) ->
    app.navigate ONBOARDING_LAYOUT, OnboardingPlugViewController
  route '/onboarding/unplug', (params) ->
    app.navigate ONBOARDING_LAYOUT, OnboardingUnplugViewController

  # Dashboard
  route '/dashboard/index:#action:', (params) ->
    app.navigate WALLET_LAYOUT, DashboardIndexViewController

  # Accounts
  route '/accounts/index{#action}{?params}', (params) ->
    l 'Accounts'