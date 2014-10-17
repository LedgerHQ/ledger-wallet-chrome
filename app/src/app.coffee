require @ledger.imports, ->

  class Application
    start: ->
      l('salut')

  @ledger.application = new Application()
  @ledger.application.start()