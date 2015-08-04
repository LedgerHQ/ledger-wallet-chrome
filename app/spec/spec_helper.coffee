@ledger.specs ||= {}

class EventReporter extends @EventEmitter

  constructor: ->
    @_isJasmineDone = yes

  promise: -> (@_defer = ledger.defer()).promise

  jasmineStarted: (result) ->
    @_results = []
    @_isJasmineDone = no
    @emit 'jasmine:started'

  suiteStarted: (result) ->
    @_lastSuite = result
    @emit 'suite:started', result

  specStarted: (result) ->
    @_lastSpec = result
    @emit 'spec:started'

  specDone: (result) ->
    @_lastSpec = null
    @_results.push result
    @emit 'spec:done', result

  suiteDone: (result) ->
    @_lastSuite = null
    @_results.push result
    @emit 'suite:done', result

  jasmineDone: ->
    @_isJasmineDone = yes
    failures = (result for result in @_results when result.failedExpectations.length > 0)
    failed = failures.length > 0
    if failed
      @_defer.reject(failures)
    else
      @_defer.resolve(@_results)
    @emit (if failed then 'jasmine:failed' else 'jasmine:succeed')
    @emit 'jasmine:done', failed

  isJasmineDone: -> @_isJasmineDone
  getLastSuite: -> @_lastSuite
  getLastSpec: -> @_lastSpec

ledger.specs.renderingNode = $('<div></div>')[0]

###
@param [Array<String>, String] filter Do a && for each word in each string, do a || between strings
###

@ledger.specs.init = (filters...) ->
  d = Q.defer()
  ledger.require ledger.specs.jasmine, =>
    @env = jasmine.getEnv()
    if filters.length > 0
      filters = ((word.toLowerCase() for word in f.split(" ")) for f in _.flatten(filters))
      @env.specFilter = @filter(filters)
    @htmlReporter = new jasmine.HtmlReporter(
      env: @env
      onRaiseExceptionsClick: -> queryString.setParam("catch", !env.catchingExceptions())
      getContainer: -> ledger.specs.renderingNode
      createElement: -> document.createElement.apply(document, arguments)
      createTextNode: -> document.createTextNode.apply(document, arguments)
      timer: new jasmine.Timer()
    )

    @env.addReporter(@htmlReporter)
    @env.addReporter(ledger.specs.reporters.events)
    ledger.require @files, =>
      # Use mock local storage
      ledger.specs.storage.inject ->
        # Restore original storage implementation
        _restoreChromeStore()
        d.resolve()
  d.promise

@ledger.specs.run = (routeToResult = yes) ->
  promise = ledger.specs.reporters.events.promise()
  #render "spec_runner", {}, (html) =>
  #  ledger.app._navigationControllerSelector().html(html)
  @htmlReporter.initialize()
  @env.execute()
  ledger.app.router.go '/specs/result' if routeToResult
  promise

@ledger.specs.initAndRun = (filters...) ->
  @init(filters...).then => @run()

@ledger.specs.initAndRunUntilItFails = (filters...) ->
  d = ledger.defer()
  ledger.specs.initAndRunUntilItFails.iteration = 0
  initAndRun = =>
    @init(filters...)
    .then => @run()
    .then =>
      ledger.specs.initAndRunUntilItFails.iteration += 1
      initAndRun()

  initAndRun().fail (failures) ->
    d.resolve(failures)

  d.promise

ledger.specs.go = -> ledger.app.router.go '/specs/index'

@ledger.specs.reporters ||= {}
@ledger.specs.reporters.events = new EventReporter()

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

###
  Restore original storage implementation
###
_restoreChromeStore = ->
  intervalID = setInterval ->
    if jsApiReporter.status() is 'done'
      ledger.specs.storage.restore ->
        clearInterval intervalID
  , 1000

