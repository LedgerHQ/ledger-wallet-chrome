@declareRoutes = (route, app) ->

  route '/dashboard/index', (params) ->
    app.navigate @WALLET_LAYOUT, new @DashboardIndexViewController()