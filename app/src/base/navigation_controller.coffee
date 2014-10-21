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
    @setControllerStylesheetPath(viewController.cssName())
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

  topViewController: ->
    @viewControllers[@viewControllers.length - 1]

  render: (selector) ->
    @renderedSelector = selector

  setControllerStylesheetPath: (path) ->
    $("link[id='controller_style']").attr('href', '../assets/css/' + path + '.css')

  renderChild: ->
    return if @viewControllers.length == 0 || !@renderedSelector?
    @topViewController().render($('#' + @childViewControllerContentId))