###
  View controllers are the bridge between models and view. They are responsible of fetching data and injecting them in views.
  View controllers are automatically bound to an eco HTML template depending of the class name. For example an instance of
  'NamespaceHereFoxyViewController' will render the template located at 'views/namespace/here/foxy.eco'.

  @example How to use the view property of view controller
    class MyFoxyViewController extends ViewController
      view:
        foxyButton: "#foxy_button"
        foxyInput: "#foxy_input"

      onAfterRender: ->
        super
        @view.foxyButton.on 'click', =>
          foxyValue = foxyInput.val()
          ... Do something with the value ...

###
class @ViewController extends @EventEmitter

  renderedSelector: undefined
  parentViewController: undefined

  ###
    A hash of view selectors that will be selected after the view render. (See the example in the class description)
  ###
  view: {}

  constructor: (params = {}, routedUrl = "") ->
    @params = _.defaults(params, @defaultParams)
    @routedUrl = routedUrl
    @_isRendered = no
    # bind all methods to self
    for key, value of @
      if _.isFunction(value) and value != @constructor
        @[key] = value.bind(@)
    @initialize()

  initialize: ->

  ###
    Selects elements in the controller node with {http://api.jquery.com/category/selectors/ jQuery selector}

    @return [jQuery.Element] The result of the selector
  ###
  select: (selectorString) ->
    $(@renderedSelector).find(selectorString)

  render: (selector) ->
    @setControllerStylesheet()
    @renderedSelector = selector
    do @onBeforeRender
    @emit 'beforeRender', {sender: @}
    render @viewPath(), @, (html) =>
      selector.html(html)
      @_isRendered = yes
      do @onAfterRender
      @emit 'afterRender', {sender: @}

  className: ->
    @constructor.name

  identifier: () ->
    @className().replace 'ViewController', ''

  assetPath: () ->
    finalName = ''
    segments = _.string.underscored(@identifier()).split('_')
    for segment in segments
      finalName += '/' + segment
    finalName

  # Gets the path to the view template file of the controller.
  viewPath: () ->
    @assetPath()

  # Gets the path to the css stylesheet of the controller.
  cssPath: () ->
    @assetPath()

  # Gets a url representation of the current view controller with its actual params
  # @return [String] The representative URL
  representativeUrl: ->
    ledger.url.createUrlWithParams(@routedUrl.parseAsUrl().pathname, @params)

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

  # Set the curre=nt stylesheet need for the controller
  setControllerStylesheet: () ->
    $("link[id='view_controller_style']").attr('href', '../assets/css/' + @cssPath() + '.css?' + (new Date()).getTime())

  # Called before the view controller is rendered
  onBeforeRender: ->

  # Called after the view controller is rendered
  onAfterRender: ->
    view = @view
    @view = {}
    for key, value of view
      continue if not value?
      @view[key] = if value.selector? then $(value.selector) else @select(value)

  # Called when the view controller is attached to a parent view controller
  onAttach: ->

  # Called when the view controller is detached from a parent view controller
  onDetach: ->

  # Checks if the UI of the current view controller is already rendered in its selector or not.
  # @return [Boolean] True if the view controller is rendered, false otherwise
  isRendered: -> @_isRendered
