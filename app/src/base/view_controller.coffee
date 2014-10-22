class @ViewController extends @EventEmitter

  renderedSelector: undefined
  parentViewController: undefined

  select: (selectorString) ->
    $(@renderedSelector).find(selectorString)

  render: (selector) ->
    @setControllerStylesheet()
    viewName = @viewName()
    @renderedSelector = selector
    do @onBeforeRender
    @emit 'beforeRender', {sender: @}
    render viewName, @, (html) =>
      selector.html(html)
      do @onAfterRender
      @emit 'afterRender', {sender: @}

  viewName: ->
    className = @constructor.name.replace 'ViewController', ''
    _.string.underscored(className)

  cssName: ->
    className = @constructor.name.replace 'ViewController', ''
    _.string.underscored(className)

  handleAction: (actionName) ->
    do @[actionName] if @[actionName]?
    yes

  setControllerStylesheet: () ->
    $("link[id='controller_style']").attr('href', '../assets/css/' + @cssName() + '.css')

  onBeforeRender: ->

  onAfterRender: ->

  onAttach: ->

  onDetach: ->

jQuery.extend(@ViewController.prototype, jQuery.EventEmitter.prototype)