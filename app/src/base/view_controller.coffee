class @ViewController extends @EventEmitter

  renderedSelector: undefined
  parentViewController: undefined

  constructor: (params) ->
    @params = params

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

  className: ->
    @.constructor.name

  identifier: () ->
    @className().replace 'ViewController', ''


  assetPath: () ->
    finalName = ''
    segments = _.string.underscored(@identifier()).split('_')
    for segment in segments
      finalName += '/' + segment
    finalName

  # Get the path to the view template file of the controller
  viewPath: () ->
    @assetPath()

  # Get the path to the css stylesheet of the controller
  cssPath: () ->
    @assetPath()

  # Request a view controller to perform an action. By default this tries to invoke a method with the name given by the
  # actionName string
  #
  # @param [String] actionName The action name
  # @param [Object] params The parameters applied to the action
  # @return [Boolean] yes if the controller is able to handle the action no otherwise
  handleAction: (actionName, params) ->
    if @[actionName]? and _.isFunction(@[actionName])
      @[actionName](params)
      return yes
    no

  # Set the current stylesheet need for the controller
  setControllerStylesheet: () ->
    $("link[id='view_controller_style']").attr('href', '../assets/css/' + @cssPath() + '.css?' + (new Date()).getTime())

  # Called before the view controller is rendered
  onBeforeRender: ->

  # Called after the view controller is rendered
  onAfterRender: ->

  # Called when the view controller is attached to a parent view controller
  onAttach: ->

  # Called when the view controller is detached from a parent view controller
  onDetach: ->
