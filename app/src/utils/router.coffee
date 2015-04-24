class @Router extends @EventEmitter

  # @private
  # @property [String] The currently routed url (private)
  currentUrl: null

  constructor: (app) ->
    @_logger = new ledger.utils.Logger("Router")

    # initialize router
    @_router = crossroads.create()
    @_router.normalizeFn = crossroads.NORM_AS_OBJECT
    @_router.ignoreState = on

    # listen events
    @_router.routed.add (url, data) =>
      oldUrl = @currentUrl
      @currentUrl = url
      @emit 'routed', {oldUrl, url, data}
    @_router.bypassed.add (url, data) =>
      e "No route found for #{url}"
      @emit 'bypassed', {url: url, data: data}


    # add routes
    declareRoutes(@_addRoute.bind(@), app)

  go: (url, params) ->
    setTimeout( =>
      path = url.parseAsUrl().pathname
      loggableUrl = url
      paramsIndex = loggableUrl.indexOf '?'
      loggableUrl = loggableUrl.substr(0, paramsIndex) if paramsIndex isnt -1
      @_logger.info("Routing to [#{loggableUrl}]")
      if ledger.app.wallet? or ledger.router.pluggedWalletRoutesExceptions.indexOf(path) != -1 or (ledger.router.ignorePluggedWalletForRouting? and ledger.router.ignorePluggedWalletForRouting == yes)
        url = ledger.url.createUrlWithParams(url, params)
        @_router.parse(url)
    , 0)

  _addRoute: (url, callback) ->
    route = @_router.addRoute url + ':?params::#action::?params:'
    route.matched.add callback.bind(route)
