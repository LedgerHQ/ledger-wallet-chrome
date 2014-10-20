class @Router extends @EventEmitter

  _currentUrl: null

  constructor: (app) ->
    # initialize router
    @_router = crossroads.create()
    @_router.normalizeFn = crossroads.NORM_AS_OBJECT

    # listen events
    @_router.routed.add (url, data) =>
      @_currentUrl = url
      @emit 'routed', {url: url, data: data}
    @_router.bypassed.add (url, data) =>
      @emit 'bypassed', {url: url, data: data}

    # add routes
    declareRoutes(@_addRoute.bind(@), app)

  go: (url, params) ->
    url = url + '?' + jQuery.params(params) if params?
    @_router.parse(url)

  _addRoute: (url, callback) ->
    @_router.addRoute url, callback