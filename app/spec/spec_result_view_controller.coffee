class @SpecResultViewController extends ledger.specs.ViewController

  view:
    content: '#jasmine-container'
    currentSuiteName: '#current_suite_name'
    currentSpecName: '#current_spec_name'

  onAfterRender: ->
    super
    @refreshView()
    @_observer?.disconnect()
    @_observer = new MutationObserver(@refreshView)
    @_observer.observe(ledger.specs.renderingNode, attributes: true, childList: true, characterData: true, subtree: true)
    ledger.specs.reporters.events.on 'spec:started suite:started jasmine:done', @refreshHeader

  refreshView: ->
    @view.content.html($(ledger.specs.renderingNode).html())
    reporter = @select('.jasmine_html-reporter')
    reporter.css 'background-color', 'transparent'
    reporter.find('.banner').remove()

  refreshHeader: ->
    @view.currentSuiteName.text(ledger.specs.reporters.events.getLastSuite()?.description or "Done!")
    @view.currentSpecName.text(" " + (ledger.specs.reporters.events.getLastSpec()?.description or ""))

  onDetach: ->
    super
    @_observer?.disconnect()
    @_observer = null
    ledger.specs.reporters.events.off 'spec:started suite:started', @refreshHeader
