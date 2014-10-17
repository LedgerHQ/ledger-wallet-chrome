class @ViewController extends @EventEmitter

  renderedSelector: undefined
  parentViewController: undefined

  select: (selectorString) ->
    $(@renderedSelector).find(selectorString)

  render: (selector) ->
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
    viewName = _.string.underscored(className)

  onBeforeRender: ->

  onAfterRender: ->

  onAttach: ->

  onDetach: ->

jQuery.extend(@ViewController.prototype, jQuery.EventEmitter.prototype)