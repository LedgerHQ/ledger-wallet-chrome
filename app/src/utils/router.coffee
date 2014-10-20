class @Router extends @EventEmitter

  _currentUrl: null

  constructor: (app) ->
    # initialize router
    @_router = crossroads.create()
    @_router.normalizeFn = crossroads.NORM_AS_OBJECT

    # listen events
    @_router.routed.add (url, data) =>
      l url, data
      @_currentUrl = url
      @emit 'routed', {url: url, data: data}
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
    @_router.addRoute url, callback

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
        l self._currentUrl, url
        self.go url
        return no
      yes