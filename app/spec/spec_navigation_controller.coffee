class @SpecNavigationController extends ledger.common.NavigationController

  _menuItemBaseUrl: {
#    '/wallet/send/': '#send-item'
#    '/wallet/receive/': '#receive-item'
#    '/wallet/accounts/': '#accounts-item'
#    '/wallet/signout/': '#signout-item'
    '/specs/index': '#index-item'
    '/specs/result': '#result-item'
  }

  view:
    balanceValue: '#balance_value'
    reloadIcon: '#reload_icon'
    currencyContainer: '#currency_container'

  constructor: ->
    super
    ledger.application.router.on 'routed', @_onRoutedUrl
    @_store = new ledger.storage.ChromeStore('specs')

  _onRoutedUrl: (event, data) ->
    {url} = data
    @updateMenu url
    ##@updateBreadcrumbs url

  renderChild: ->
    if window.jasmine?
     super()
    else
      ledger.specs.init().then =>
       super()
      .done()

  onAfterRender: () ->
    super
    url = ledger.application.router.currentUrl
    @updateMenu url
    @_updateReloadIconState()
    ledger.specs.reporters.events.on 'jasmine:started jasmine:done', @_updateReloadIconState

  launchSpecs: (filters...) ->
    return unless ledger.specs.reporters.events.isJasmineDone()
    @_store.set lastSpec: filters
    ledger.specs.initAndRun(filters...)

  runAllSpecs: () -> @launchSpecs()

  runLast: -> @_store.get ['lastSpec'], (result) => @launchSpecs((result.lastSpec or [])...)

  updateMenu: (url) ->
    for baseUrl, itemSelector of @_menuItemBaseUrl
      if _.str.startsWith url, baseUrl
        menuItem = @select(itemSelector)
        unless menuItem.hasClass 'selected'
          previousItem = @select('li.selected')
          if previousItem.length > 0
            previousSelector = previousItem.find('.selector')
            color = previousSelector.css('background-color')
            previousItem.removeClass 'selected'
            previousSelector.css('background-color', color)
            previousItem.find('.selector').animate {bottom: '-10px'}, 200,  ->
              previousSelector.css('background-color', '')
              previousSelector.css('bottom', '0px')
            menuItem.addClass 'selected'
            newSelector = menuItem.find '.selector'
            newSelector.css('bottom', '-10px')
            newSelector.animate {bottom: '0px'}, 200
          else
            menuItem.addClass 'selected'
        break

  _updateReloadIconState: =>
    unless ledger.specs.reporters.events.isJasmineDone()
      @view.reloadIcon.addClass 'spinning'
    else
      @view.reloadIcon.removeClass 'spinning'