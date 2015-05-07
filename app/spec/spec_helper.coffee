@ledger.specs ||= {}

###
@param [Array<String>, String] filter Do a && for each word in each string, do a || between strings
###
@ledger.specs.init = (filters...) ->
  d = Q.defer()
  require ledger.specs.jasmine, =>
    @env = jasmine.getEnv()
    if filters.length > 0
      filters = ((word.toLowerCase() for word in f.split(" ")) for f in _.flatten(filters))
      @env.specFilter = @filter(filters)
    @htmlReporter = new jasmine.HtmlReporter(
      env: @env
      onRaiseExceptionsClick: -> queryString.setParam("catch", !env.catchingExceptions())
      getContainer: -> document.getElementById("jasmine-container")
      createElement: -> document.createElement.apply(document, arguments)
      createTextNode: -> document.createTextNode.apply(document, arguments)
      timer: new jasmine.Timer()
    )
    @env.addReporter(@htmlReporter)
    require @files, =>
      d.resolve()
  d.promise

@ledger.specs.run = () ->
  render "spec_runner", {}, (html) =>
    ledger.app._navigationControllerSelector().html(html)
    @htmlReporter.initialize()
    @env.execute()

@ledger.specs.initAndRun = (filters...) ->
  @init(filters...).then => @run()

###
Do a && for each word in each string, do a || between strings
@param [Array<Array<String>>] filters
###
@ledger.specs.filter = (filters) ->
  (spec) ->
    fullName = spec.getFullName().toLowerCase()
    for filter in filters
      match = true
      for word in filter
        match = fullName.indexOf(word) != -1
        break unless match
      return true if match
    return false
