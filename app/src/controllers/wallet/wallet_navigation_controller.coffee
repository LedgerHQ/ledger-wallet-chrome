class @WalletNavigationController extends @NavigationController

  _menuItemBaseUrl: {
#    '/wallet/dashboard/': '#dashboard-item'
#    '/wallet/send/': '#send-item'
#    '/wallet/receive/': '#receive-item'
#    '/wallet/accounts/': '#accounts-item'
#    '/wallet/signout/': '#signout-item'
    '/wallet/accounts/': '#account-item'
  }
  view:
    balanceValue: '#balance-value'
    reloadIcon: '#reload_icon'

  constructor: () ->
    ledger.application.router.on 'routed', (event, data) =>
      {url} = data
      @updateMenu url
      ##@updateBreadcrumbs url

  onAfterRender: () ->
    super
    url = ledger.application.router.currentUrl
    @updateMenu url
    ##@updateBreadcrumbs url
    @_listenBalanceEvents()
    @_listenSynchronizationEvents()

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

  _listenBalanceEvents: ->
    # fetch balances
    balance = Wallet.instance.getBalance()
    @view.balanceValue.text ledger.formatters.bitcoin.fromValue(balance.wallet.total)
    # listen events
    ledger.app.on 'wallet:balance:changed', (event, balance) =>
      @view.balanceValue.text ledger.formatters.bitcoin.fromValue(balance.wallet.total)

  _listenSynchronizationEvents: ->
    @view.reloadIcon.on 'click', =>
      Wallet.instance.retrieveAccountsBalances()
      ledger.tasks.OperationsConsumptionTask.instance.startIfNeccessary()
      _.defer => @_updateReloadIconState()
    ledger.app.on 'wallet:balance:changed wallet:balance:unchanged wallet:balance:failed wallet:operations:sync:failed wallet:operations:sync:done', (e) =>
      _.defer => @_updateReloadIconState()
    ledger.tasks.OperationsSynchronizationTask.instance.on 'start stop', =>
      _.defer => @_updateReloadIconState()
    @_updateReloadIconState()

  _updateReloadIconState: =>
    if @_isSynchronizationRunning()
      @view.reloadIcon.addClass 'spinning'
    else
      @view.reloadIcon.removeClass 'spinning'

  _isSynchronizationRunning: ->
    return ledger.tasks.OperationsConsumptionTask.instance.isRunning()