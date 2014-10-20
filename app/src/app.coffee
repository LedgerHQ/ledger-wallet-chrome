require @ledger.imports, ->

  class Application
    _navigationController = new @LedgerNavigationController()

    start: ->
      _navigationController.render $('body')

  @ledger.application = new Application()
  @ledger.application.start()