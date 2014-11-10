class @Router extends @EventEmitter

  # @private
  # @property [String] The currently routed url (private)
  currentUrl: null

  constructor: (app) ->
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

    do @_listenClickEvents

    # add routes
    declareRoutes(@_addRoute.bind(@), app)

  go: (url, params) ->
    setTimeout( =>
      url = ledger.url.createUrlWithParams(url, params)
      @_router.parse(url)
    , 0)

  _addRoute: (url, callback) ->
    route = @_router.addRoute url + ':?params::#action::?params:'
    route.matched.add callback.bind(route)

  _listenClickEvents: () ->
    self = @
    # Redirect every in-app link with our router
    $('body').delegate 'a', 'click', (e) ->
      if @href? and @protocol == 'chrome-extension:'
        url = null
        if  _.str.startsWith(@pathname, '/views/') and self.currentUrl?
          url = ledger.url.createRelativeUrlWithFragmentedUrl(self.currentUrl, @href)
        else
          url = @pathname + @search + @hash
        self.go url
        return no
      yes

    $('body').delegate '[data-href]', 'click', (e) ->
      href = $(this).attr('data-href')
      if href? and href.length > 0
        parser = href.parseAsUrl()
        if  _.str.startsWith(parser.pathname, '/views/') and self.currentUrl?
          url = ledger.url.createRelativeUrlWithFragmentedUrl(self.currentUrl, href)
        else
          url = parser.pathname + parser.search + parser.hash
        self.go url
        return no
      yes
