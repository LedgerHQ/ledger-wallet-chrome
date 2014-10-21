@declareRoutes = (route, app) ->

  route '/dashboard/index:#action:', (params) ->
    app.navigate WALLET_LAYOUT, DashboardIndexViewController

  route '/accounts/index{#action}{?params}', (params) ->
    l 'Accounts'