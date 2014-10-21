class @Router extends @EventEmitter

  _currentUrl: null

  constructor: (app) ->
    # initialize router
    @_router = crossroads.create()
    @_router.normalizeFn = crossroads.NORM_AS_OBJECT
    @_router.ignoreState = on

    # listen events
    @_router.routed.add (url, data) =>
      oldUrl = @_currentUrl
      @_currentUrl = url
      @emit 'routed', {oldUrl, url, data}
    @_router.bypassed.add (url, data) =>
      e "No route found for #{url}"
      @emit 'bypassed', {url: url, data: data}

    do @_listenClickEvents

    # add routes
    declareRoutes(@_addRoute.bind(@), app)

  go: (url, params) ->
    url = url + '?' + jQuery.params(params) if params?

    @_router.parse(url)

  _addRoute: (url, callback) ->
    route = @_router.addRoute url
    route.matched.add callback.bind(route)

  _listenClickEvents: () ->
    self = @
    # Redirect every in-app link with our router
    $('body').delegate 'a', 'click', ->
      if @href? and @protocol == 'chrome-extension:'
        url = null
        if  _.str.startsWith(@pathname, '/views/') and self._currentUrl?
          url = ledger.url.createRelativeUrlWithFragmentedUrl(self._currentUrl, @href)
        else
          url = @pathname + @search + @hash
        self.go url
        return no
      yes