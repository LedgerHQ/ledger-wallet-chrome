@declareRoutes = (route, app) ->

  route '/dashboard/index', (params) ->
    l(window.location)
    app.navigate @WALLET_LAYOUT, new @DashboardIndexViewController()