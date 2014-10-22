class @ViewController extends @EventEmitter

  renderedSelector: undefined
  parentViewController: undefined

  select: (selectorString) ->
    $(@renderedSelector).find(selectorString)

  render: (selector) ->
    @setControllerStylesheet()
    @renderedSelector = selector
    do @onBeforeRender
    @emit 'beforeRender', {sender: @}
    render @viewPath(), @, (html) =>
      selector.html(html)
      do @onAfterRender
      @emit 'afterRender', {sender: @}

  identifier: () ->
    @className().replace 'ViewController', ''

  assetPath: () ->
    finalName = ''
    segments = _.string.underscored(@identifier()).split('_')
    for segment in segments
      finalName += '/' + segment
    finalName

  viewPath: () ->
    @assetPath()

  cssPath: () ->
    @assetPath()

  handleAction: (actionName) ->
    do @[actionName] if @[actionName]?
    yes

  setControllerStylesheet: () ->
    $("link[id='view_controller_style']").attr('href', '../assets/css' + @cssPath() + '.css')

  onBeforeRender: ->

  onAfterRender: ->

  onAttach: ->

  onDetach: ->

jQuery.extend(@ViewController.prototype, jQuery.EventEmitter.prototype)