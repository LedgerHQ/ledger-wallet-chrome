@ledger.specs ||= {}
@ledger.specs.run = (specsToRun = null) ->
  render "spec_runner", {}, (html) ->
    ledger.app._navigationControllerSelector().html(html)
    env = jasmine.getEnv()
    htmlReporter = new jasmine.HtmlReporter(
      env: env
      onRaiseExceptionsClick: -> queryString.setParam("catch", !env.catchingExceptions())
      getContainer: -> document.getElementById("jasmine-container")
      createElement: -> document.createElement.apply(document, arguments)
      createTextNode: -> document.createTextNode.apply(document, arguments)
      timer: new jasmine.Timer()
    )
    env.addReporter(htmlReporter)
    htmlReporter.initialize()
    env.execute(specsToRun)
  return