# Base class for navigation controllers. This class is responsible of layouting view controllers inside its
# selector. The navigation controllers may be able to handle the navigation history (pushing/popping view controllers)
# It dispatch routing action action to its child...
#
# @event push Called when a view controller is pushed
# @event pop Called when a view controller is popped
class @NavigationController extends @ViewController

  _historyLength: 1
  viewControllers: []
  childViewControllerContentId: 'navigation_controller_content'

  push: (viewController) ->
    if @topViewController()?
      @topViewController().onDetach()
      @topViewController().parentViewController = undefined
    if @viewControllers.length >= @_historyLength
      @viewControllers.splice(0, 1)
    @viewControllers.push viewController
    viewController.parentViewController = @
    viewController.onAttach()
    do @renderChild
    @emit 'push', {sender: @, viewController: viewController}

  pop: ->
    viewController = @viewControllers.pop()
    viewController.onDetach()
    viewController.parentViewController = undefined
    if @topViewController()?
      @topViewController().parentViewController = @
      @topViewController().onAttach()
    do @renderChild
    @emit 'pop', {sender: @, viewController: viewController}
    viewController

  identifier: () ->
    @className().replace 'NavigationController', ''

  viewPath: () ->
    @assetPath() + @assetPath()

  cssPath: () ->
    @assetPath() + @assetPath()

  render: (selector) ->
    @renderedSelector = selector
    do @onBeforeRender
    @emit 'beforeRender', @
    render @viewPath(), @, (html) =>
      @setControllerStylesheet =>
        selector.html(html)
        do @renderChild
        do @onAfterRender
        @emit 'afterRender', @

  topViewController: ->
    @viewControllers[@viewControllers.length - 1]

  stylesheetIdentifier: -> "navigation_controller_style"

  renderChild: ->
    return if @viewControllers.length == 0 || !@renderedSelector?
    @topViewController().render($('#' + @childViewControllerContentId))

  # @override ViewController.handleAction
  # Dispatch the action to the view controller
  handleAction: (actionName, params) ->
    unless super
      return @topViewController()?.handleAction(actionName, params)
    yes
