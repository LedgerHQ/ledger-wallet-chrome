class @AppsCoinkiteNavigationController extends @NavigationController

  _menuItemBaseUrl: {
    '/apps/coinkite/dashboard/index': '#dashboard-item'
    '/apps/coinkite/key/': '#key-item'
    '/apps/coinkite/sign/': '#cosign-item'
    '/apps/coinkite/settings/': '#settings-item'
  }

  constructor: () ->
    ledger.application.router.on 'routed', (event, data) =>
      {url} = data
      @updateMenu url

  onAfterRender: () ->
    super
    url = ledger.application.router.currentUrl
    @updateMenu url

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

  viewPath: () ->
    @assetPath() + "/coinkite"

  cssPath: () ->
    @assetPath() + "/coinkite"