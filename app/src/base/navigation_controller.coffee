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
    @setControllerStylesheet()
    @renderedSelector = selector
    do @onBeforeRender
    @emit 'beforeRender', @
    render @viewPath(), @, (html) =>
      selector.html(html)
      do @renderChild
      do @onAfterRender
      @emit 'afterRender', @

  topViewController: ->
    @viewControllers[@viewControllers.length - 1]

  setControllerStylesheet: () ->
    $("link[id='navigation_controller_style']").attr('href', '../assets/css/' + @cssPath() + '.css?' + (new Date()).getTime())

  renderChild: ->
    return if @viewControllers.length == 0 || !@renderedSelector?
    @topViewController().render($('#' + @childViewControllerContentId))

  handleAction: (actionName) ->
    if @[actionName]?
      do @[actionName]
    else
      return @topViewController()?.handleAction(actionName)