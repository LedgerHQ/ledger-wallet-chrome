class @WalletNavigationController extends @NavigationController

  _menuItemBaseUrl: {
    '/wallet/dashboard/': '#dashboard-item'
    '/wallet/send/': '#send-item'
    '/wallet/receive/': '#receive-item'
    '/wallet/accounts/': '#accounts-item'
    '/wallet/signout/': '#signout-item'
  }

  constructor: () ->
    ledger.application.router.on 'routed', (event, data) =>
      {url} = data
      @updateMenu url
      @updateBreadcrumbs url

  onAfterRender: () ->
    url = ledger.application.router.currentUrl
    @updateMenu url
    @updateBreadcrumbs url

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

  updateBreadcrumbs: (url) ->
    return unless url?
    breadcrumbs = $('#breadcrumbs')
    return if breadcrumbs.length == 0
    $('breadcrumbs').empty()
    breadcrumbs.html(url)
    fragmentedUrl = url.split('/')
    fragmentedUrl.splice(0, 2)
    fragmentedUrl.splice(fragmentedUrl.length - 1, 1) if fragmentedUrl[fragmentedUrl.length - 1] == 'index'

